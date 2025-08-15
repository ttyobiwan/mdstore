defmodule MdstoreWeb.AdminLive.Products.Form do
  use MdstoreWeb, :live_view
  alias Mdstore.Products
  alias Mdstore.Images
  alias Mdstore.Products.Product
  import MdstoreWeb.MdComponents

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
    <div class="max-w-2xl mx-auto">
      <div class="card bg-base-100 border border-base-content/20 rounded-none shadow-sm">
        <div class="card-body p-8">
          <h2 class="card-title text-2xl text-base-content mb-6">{@page_title}</h2>

          <.form for={@form} id="form" phx-change="validate" phx-submit="save" class="space-y-6">
            <.md_input field={@form[:name]} type="text" label="Name" />
            <.md_input field={@form[:description]} type="textarea" label="Description" />
            <.md_input field={@form[:quantity]} type="number" label="Quantity" />
            <.md_input field={@form[:price]} type="number" label="Price" step="0.01" />

            <div class="form-control">
              <label class="label">
                <span class="label-text text-base-content">Front Image</span>
              </label>

              <div
                :if={@product.front_image && !Enum.any?(@uploads.front_image.entries)}
                class="mb-4 p-4 border border-base-content/20 bg-base-200"
              >
                <p class="text-sm text-base-content/70 mb-2">Current image:</p>
                <img
                  src={Images.get_image_link(@product.front_image)}
                  alt="Current front image"
                  class="w-20 h-20 object-cover border border-base-content/20"
                />
              </div>

              <div class="file-input-wrapper">
                <.live_file_input
                  upload={@uploads.front_image}
                  class="file-input file-input-bordered w-full border-base-content/20 rounded-none"
                />
              </div>

              <div
                :for={entry <- @uploads.front_image.entries}
                class="flex items-center gap-3 mt-3 p-3 border border-base-content/20 bg-base-100"
              >
                <.live_img_preview entry={entry} width="75" class="border border-base-content/20" />
                <span class="text-base-content">{entry.client_name}</span>
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  class="btn btn-sm btn-square btn-ghost text-base-content/60 hover:text-error"
                >
                  <.icon name="hero-x-mark" class="size-4" />
                </button>
              </div>

              <div :if={
                Enum.any?(
                  @uploads.front_image.entries,
                  &(upload_errors(@uploads.front_image, &1) != [])
                )
              }>
                <div :for={entry <- @uploads.front_image.entries}>
                  <div :for={err <- upload_errors(@uploads.front_image, entry)} class="label">
                    <span class="label-text-alt text-error">{error_to_string(err)}</span>
                  </div>
                </div>
              </div>
              <div
                :if={
                  !Enum.any?(
                    @uploads.front_image.entries,
                    &(upload_errors(@uploads.front_image, &1) != [])
                  ) && Keyword.get(@form.errors, :front_image_id)
                }
                class="label"
              >
                <span class="label-text-alt text-error">
                  {elem(Keyword.get(@form.errors, :front_image_id), 0)}
                </span>
              </div>
            </div>

            <div class="card-actions justify-end pt-4">
              <.md_button variant="primary" phx-disable-with="Saving..." disabled={@form.errors != []}>
                Save product
              </.md_button>
            </div>
          </.form>
        </div>
      </div>
    </div>
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

    cond do
      has_existing_image ->
        # There must be a valid front_image_id
        params

      has_new_upload ->
        # Prepopulate front_image_id - its going to be replaced when consuming
        Map.put(params, "front_image_id", -1)

      true ->
        # Drop image front_image_id to force the validation
        Map.put(params, "front_image_id", nil)
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
