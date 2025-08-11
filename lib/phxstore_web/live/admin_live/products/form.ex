defmodule PhxstoreWeb.AdminLive.Products.Form do
  alias Phxstore.Images
  use PhxstoreWeb, :live_view
  alias Phxstore.Products
  alias Phxstore.Products.Product

  def mount(params, _session, socket) do
    socket =
      socket
      |> allow_upload(
        :front_image,
        accept: ~w(.jpg .jpeg .png),
        max_entries: 1,
        max_file_size: 5_000_000
      )
      |> apply_action(socket.assigns.live_action, params)

    {:ok, socket}
  end

  defp apply_action(socket, :new, _params) do
    product = %Product{front_image: nil}

    socket
    |> assign(page_title: "Create product")
    |> assign(:product, product)
    |> assign(:form, to_form(Product.changeset(product, %{})))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    product = Products.get_product(id)

    socket
    |> assign(page_title: "Edit product")
    |> assign(:product, product)
    |> assign(:form, to_form(Product.changeset(product, %{})))
  end

  def render(assigns) do
    ~H"""
    <.form for={@form} id="form" phx-change="validate" phx-submit="save">
      <.input field={@form[:name]} type="text" label="Name" />
      <.input field={@form[:description]} type="text" label="Description" />
      <.input field={@form[:quantity]} type="number" label="Quantity" />
      <.input field={@form[:price]} type="number" label="Price" />

      <div>
        <%= if @product.front_image && !Enum.any?(@uploads.front_image.entries) do %>
          <div class="mb-2">
            <p class="text-sm text-gray-600">Current image:</p>
            <img
              src={Images.get_image_link(@product.front_image)}
              alt="Current front image"
              class="w-20 h-20 object-cover"
            />
          </div>
        <% end %>

        <.live_file_input upload={@uploads.front_image} />

        <%= for entry <- @uploads.front_image.entries do %>
          <div class="flex items-center gap-2">
            <.live_img_preview entry={entry} width="75" />
            <span>{entry.client_name}</span>
            <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref}>×</button>
          </div>
        <% end %>

        <%= for err <- upload_errors(@uploads.front_image) do %>
          <p class="text-red-500">{error_to_string(err)}</p>
        <% end %>

        <%= if @form[:front_image_id].errors != [] do %>
          <p class="text-red-500">Front image is required</p>
        <% end %>
      </div>

      <.button phx-disable-with="Saving...">Save product</.button>
    </.form>
    """
  end

  defp error_to_string(:too_large), do: "File too large"
  defp error_to_string(:not_accepted), do: "Invalid file type"
  defp error_to_string(:too_many_files), do: "Too many files"

  def handle_event("validate", %{"product" => params}, socket) do
    params = validate_image(socket, params)
    changeset = Product.changeset(socket.assigns.product, params)
    socket = socket |> assign(form: to_form(changeset, action: :validate))
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :front_image, ref)}
  end

  def handle_event("save", %{"product" => params}, socket) do
    save_product(socket, params, socket.assigns.live_action)
  end

  defp validate_image(socket, params) do
    has_existing_image = socket.assigns.product.front_image_id != nil
    has_new_upload = Enum.any?(socket.assigns.uploads.front_image.entries)

    if has_existing_image || has_new_upload do
      params
    else
      Map.delete(params, "front_image_id")
    end
  end

  # Create new product and save the image.
  defp save_product(socket, params, :new) do
    with {:ok, updated_params} <-
           save_image(socket, params, socket.assigns.uploads.front_image.entries),
         {:ok, _product} <- Products.create_product(updated_params) do
      socket =
        socket
        |> put_flash(:info, "Product created successfully")
        |> push_navigate(to: ~p"/admin/products")

      {:noreply, socket}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        socket =
          socket
          |> put_flash(:error, "Errors while creating product")
          |> assign(:form, to_form(changeset))

        {:noreply, socket}

      {:error, _reason} ->
        socket =
          socket
          |> put_flash(:error, "Error while saving the image")

        {:noreply, socket}
    end
  end

  # Update existing product, update image if any uploads are present, and delete the existing image.
  defp save_product(socket, params, :edit) do
    with {:ok, updated_params} <-
           save_image(socket, params, socket.assigns.uploads.front_image.entries),
         {:ok, _product} <- Products.update_product(socket.assigns.product, updated_params),
         {:ok, _deleted_image} <-
           delete_image(socket, params, socket.assigns.uploads.front_image.entries) do
      socket =
        socket
        |> put_flash(:info, "Product updated successfully")
        |> push_navigate(to: ~p"/admin/products")

      {:noreply, socket}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        socket =
          socket
          |> put_flash(:error, "Errors while updating product")
          |> assign(:form, to_form(changeset))

        {:noreply, socket}

      {:error, _reason} ->
        socket =
          socket
          |> put_flash(:error, "Error while updating front image")

        {:noreply, socket}
    end
  end

  defp save_image(_socket, params, []) do
    {:ok, params}
  end

  defp save_image(socket, params, _uploads) do
    case consume_uploaded_entries(socket, :front_image, fn %{path: path}, entry ->
           Images.create_image(path, entry.uuid, entry.client_name)
         end) do
      [image] ->
        {:ok, Map.put(params, "front_image_id", image.id)}

      [{:error, reason}] ->
        {:error, reason}

      [] ->
        {:error, "No files uploaded"}
    end
  end

  defp delete_image(_socket, _params, []) do
    {:ok, nil}
  end

  defp delete_image(socket, _params, _uploads) do
    Images.delete_image(socket.assigns.product.front_image)
  end
end
