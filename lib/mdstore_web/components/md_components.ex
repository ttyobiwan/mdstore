defmodule MdstoreWeb.MdComponents do
  use Phoenix.Component

  use Gettext, backend: MdstoreWeb.Gettext

  @doc """
  Renders a markdown-styled table with zebra striping.

  ## Examples

      <.md_table id="users" rows={@users}>
        <:col :let={user} label="ID">{user.id}</:col>
        <:col :let={user} label="Username">{user.username}</:col>
      </.md_table>
  """
  attr :id, :string, required: true
  attr :class, :string, default: ""
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def md_table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-x-auto border border-base-content/20">
      <table class={["table table-zebra table-xs", @class]}>
        <thead class="border-b border-base-content/20">
          <tr class="bg-base-content/5">
            <th
              :for={col <- @col}
              class="font-semibold text-base-content border-r border-base-content/10 last:border-r-0"
            >
              {col[:label]}
            </th>
            <th :if={@action != []} class="font-semibold text-base-content">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
          <tr
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            class={[
              "border-b border-base-content/10 hover:bg-base-content/10 transition-colors",
              @row_click && "cursor-pointer"
            ]}
          >
            <td
              :for={col <- @col}
              phx-click={@row_click && @row_click.(row)}
              class="py-1 px-2 border-r border-base-content/5 last:border-r-0"
            >
              {render_slot(col, @row_item.(row))}
            </td>
            <td :if={@action != []} class="py-1 px-2">
              <div class="flex gap-1 justify-end">
                <%= for action <- @action do %>
                  {render_slot(action, @row_item.(row))}
                <% end %>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a markdown-styled button with sharp borders.

  ## Examples

      <.md_button>Send!</.md_button>
      <.md_button variant="primary">Send!</.md_button>
      <.md_button navigate={~p"/"}>Home</.md_button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :string, default: ""
  attr :variant, :string, values: ~w(primary secondary small)
  slot :inner_block, required: true

  def md_button(%{rest: rest} = assigns) do
    base_classes = [
      "font-medium border-2 transition-colors duration-150",
      "focus:outline-none focus:ring-2 focus:ring-offset-2",
      "disabled:opacity-50 disabled:cursor-not-allowed"
    ]

    variant_classes =
      case assigns[:variant] do
        "primary" ->
          [
            "px-4 py-2",
            "bg-black text-white border-black",
            "hover:bg-white hover:text-black",
            "dark:bg-white dark:text-black dark:border-white",
            "dark:hover:bg-black dark:hover:text-white",
            "focus:ring-gray-500"
          ]

        "secondary" ->
          [
            "px-4 py-2",
            "bg-white text-black border-black",
            "hover:bg-black hover:text-white",
            "dark:bg-black dark:text-white dark:border-white",
            "dark:hover:bg-white dark:hover:text-black",
            "focus:ring-gray-500"
          ]

        "small" ->
          [
            "px-2 py-1 text-xs",
            "bg-white text-black border-black",
            "hover:bg-black hover:text-white",
            "dark:bg-black dark:text-white dark:border-white",
            "dark:hover:bg-white dark:hover:text-black",
            "focus:ring-gray-500"
          ]

        _ ->
          [
            "px-4 py-2",
            "bg-white text-black border-black",
            "hover:bg-black hover:text-white",
            "dark:bg-black dark:text-white dark:border-white",
            "dark:hover:bg-white dark:hover:text-black",
            "focus:ring-gray-500"
          ]
      end

    assigns = assign(assigns, :class, [base_classes, variant_classes, assigns.class])

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end
end
