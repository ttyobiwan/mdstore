defmodule MdstoreWeb.MdComponents do
  use Phoenix.Component

  use Gettext, backend: MdstoreWeb.Gettext
  import MdstoreWeb.CoreComponents

  @doc """
  Renders a markdown-styled table with zebra striping.

  ## Examples

      <.md_table id="users" rows={@users}>
        <:col :let={user} label="ID">{user.id}</:col>
        <:col :let={user} label="Username">{user.username}</:col>
      </.md_table>
  """
  attr :id, :string, required: true
  attr :class, :string, default: nil
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  attr :size, :string, values: ~w(xs sm md lg xl), default: "md"
  attr :zebra, :boolean, default: true
  attr :pin_rows, :boolean, default: false
  attr :pin_cols, :boolean, default: false

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def md_table(assigns) do
    sizes = %{
      "xs" => "table-xs",
      "sm" => "table-sm",
      "md" => "table-md",
      "lg" => "table-lg",
      "xl" => "table-xl"
    }

    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end
      |> assign(
        :class,
        assigns[:class] ||
          [
            "table",
            assigns[:zebra] && "table-zebra",
            assigns[:pin_rows] && "table-pin-rows",
            assigns[:pin_cols] && "table-pin-cols",
            Map.fetch!(sizes, assigns[:size])
          ]
      )

    ~H"""
    <div class="overflow-x-auto border border-base-content/20">
      <table class={@class}>
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
  Renders a button with markdown-style design.

  ## Examples

      <.md_button>Send!</.md_button>
      <.md_button phx-click="go" variant="primary">Send!</.md_button>
      <.md_button navigate={~p"/"}>Home</.md_button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :string

  attr :variant, :string,
    values: ~w(primary secondary neutral outline ghost error),
    default: "neutral"

  attr :size, :string, values: ~w(xs sm md lg xl), default: "md"
  slot :inner_block, required: true

  def md_button(%{rest: rest} = assigns) do
    variants = %{
      "primary" => "btn-primary",
      "secondary" => "btn-secondary",
      "neutral" => "btn-neutral",
      "outline" => "btn-outline btn-neutral",
      "ghost" => "btn-ghost",
      "error" => "btn-error",
      nil => "btn-neutral"
    }

    sizes = %{
      "xs" => "btn-xs",
      "sm" => "btn-sm",
      "md" => "btn-md",
      "lg" => "btn-lg",
      "xl" => "btn-xl"
    }

    base_classes = [
      "btn rounded-none",
      Map.fetch!(variants, assigns[:variant]),
      Map.fetch!(sizes, assigns[:size])
    ]

    assigns =
      assign(assigns, :class, [
        base_classes,
        assigns[:class]
      ])

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

  @doc """
  Renders a markdown-styled input.

  ## Examples

      <.md_input field={@form[:name]} type="text" label="Name" />
      <.md_input type="select" name="category" options={@categories} />
      <.md_input type="select" name="status" options={@statuses} variant="primary" />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week)

  attr :prompt, :string, default: nil
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false
  attr :class, :string, default: nil

  attr :variant, :string,
    values: ~w(neutral primary secondary accent info success warning error ghost),
    default: "neutral"

  attr :size, :string, values: ~w(xs sm md lg xl), default: "md"
  attr :errors, :list, default: []

  attr :rest, :global, include: ~w(autocomplete form readonly disabled step min max)

  def md_input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> md_input()
  end

  def md_input(%{type: "select"} = assigns) do
    variants = %{
      "neutral" => "select-neutral",
      "primary" => "select-primary",
      "secondary" => "select-secondary",
      "accent" => "select-accent",
      "info" => "select-info",
      "success" => "select-success",
      "warning" => "select-warning",
      "error" => "select-error",
      "ghost" => "select-ghost"
    }

    sizes = %{
      "xs" => "select-xs",
      "sm" => "select-sm",
      "md" => "select-md",
      "lg" => "select-lg",
      "xl" => "select-xl"
    }

    assigns =
      assigns
      |> assign_new(:id, fn -> assigns[:name] end)
      |> assign(
        :class,
        assigns[:class] ||
          [
            "select w-full border-base-content/20 rounded-none",
            Map.fetch!(variants, assigns[:variant]),
            Map.fetch!(sizes, assigns[:size]),
            assigns[:errors] != [] && "select-error"
          ]
      )

    ~H"""
    <div class="form-control">
      <label :if={@label} class="label">
        <span class="label-text text-base-content">{@label}</span>
      </label>
      <select id={@id} name={@name} class={@class} multiple={@multiple} {@rest}>
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <div :if={@errors != []} class="label">
        <span :for={msg <- @errors} class="label-text-alt text-error">{msg}</span>
      </div>
    </div>
    """
  end

  def md_input(%{type: "textarea"} = assigns) do
    variants = %{
      "neutral" => "textarea-neutral",
      "primary" => "textarea-primary",
      "secondary" => "textarea-secondary",
      "accent" => "textarea-accent",
      "info" => "textarea-info",
      "success" => "textarea-success",
      "warning" => "textarea-warning",
      "error" => "textarea-error",
      "ghost" => "textarea-ghost"
    }

    sizes = %{
      "xs" => "textarea-xs",
      "sm" => "textarea-sm",
      "md" => "textarea-md",
      "lg" => "textarea-lg",
      "xl" => "textarea-xl"
    }

    assigns =
      assigns
      |> assign_new(:id, fn -> assigns[:name] end)
      |> assign(
        :class,
        assigns[:class] ||
          [
            "textarea w-full border-base-content/20 rounded-none",
            Map.fetch!(variants, assigns[:variant]),
            Map.fetch!(sizes, assigns[:size]),
            assigns[:errors] != [] && "textarea-error"
          ]
      )

    ~H"""
    <div class="form-control">
      <label :if={@label} class="label">
        <span class="label-text text-base-content">{@label}</span>
      </label>
      <textarea id={@id} name={@name} class={@class} {@rest}>{@value}</textarea>
      <div :if={@errors != []} class="label">
        <span :for={msg <- @errors} class="label-text-alt text-error">{msg}</span>
      </div>
    </div>
    """
  end

  def md_input(%{type: "file"} = assigns) do
    variants = %{
      "neutral" => "file-input-neutral",
      "primary" => "file-input-primary",
      "secondary" => "file-input-secondary",
      "accent" => "file-input-accent",
      "info" => "file-input-info",
      "success" => "file-input-success",
      "warning" => "file-input-warning",
      "error" => "file-input-error",
      "ghost" => "file-input-ghost"
    }

    sizes = %{
      "xs" => "file-input-xs",
      "sm" => "file-input-sm",
      "md" => "file-input-md",
      "lg" => "file-input-lg",
      "xl" => "file-input-xl"
    }

    assigns =
      assigns
      |> assign_new(:id, fn -> assigns[:name] end)
      |> assign(
        :class,
        assigns[:class] ||
          [
            "file-input w-full border-base-content/20 rounded-none",
            Map.fetch!(variants, assigns[:variant]),
            Map.fetch!(sizes, assigns[:size]),
            assigns[:errors] != [] && "file-input-error"
          ]
      )

    ~H"""
    <div class="form-control">
      <label :if={@label} class="label">
        <span class="label-text text-base-content">{@label}</span>
      </label>
      <input type="file" id={@id} name={@name} class={@class} {@rest} />
      <div :if={@errors != []} class="label">
        <span :for={msg <- @errors} class="label-text-alt text-error">{msg}</span>
      </div>
    </div>
    """
  end

  def md_input(%{type: "checkbox"} = assigns) do
    variants = %{
      "neutral" => "checkbox-neutral",
      "primary" => "checkbox-primary",
      "secondary" => "checkbox-secondary",
      "accent" => "checkbox-accent",
      "info" => "checkbox-info",
      "success" => "checkbox-success",
      "warning" => "checkbox-warning",
      "error" => "checkbox-error",
      "ghost" => "checkbox-ghost"
    }

    sizes = %{
      "xs" => "checkbox-xs",
      "sm" => "checkbox-sm",
      "md" => "checkbox-md",
      "lg" => "checkbox-lg",
      "xl" => "checkbox-xl"
    }

    assigns =
      assigns
      |> assign_new(:id, fn -> assigns[:name] end)
      |> assign_new(:checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)
      |> assign(
        :class,
        assigns[:class] ||
          [
            "checkbox rounded-none border-base-content/20",
            Map.fetch!(variants, assigns[:variant]),
            Map.fetch!(sizes, assigns[:size]),
            assigns[:errors] != [] && "checkbox-error"
          ]
      )

    ~H"""
    <div class="form-control">
      <label class="cursor-pointer label justify-start gap-3">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class={@class}
          {@rest}
        />
        <span :if={@label} class="label-text text-base-content">{@label}</span>
      </label>
      <div :if={@errors != []} class="label">
        <span :for={msg <- @errors} class="label-text-alt text-error">{msg}</span>
      </div>
    </div>
    """
  end

  def md_input(assigns) do
    variants = %{
      "neutral" => "input-neutral",
      "primary" => "input-primary",
      "secondary" => "input-secondary",
      "accent" => "input-accent",
      "info" => "input-info",
      "success" => "input-success",
      "warning" => "input-warning",
      "error" => "input-error",
      "ghost" => "input-ghost"
    }

    sizes = %{
      "xs" => "input-xs",
      "sm" => "input-sm",
      "md" => "input-md",
      "lg" => "input-lg",
      "xl" => "input-xl"
    }

    assigns =
      assigns
      |> assign_new(:id, fn -> assigns[:name] end)
      |> assign(
        :class,
        assigns[:class] ||
          [
            "input w-full border-base-content/20 rounded-none",
            Map.fetch!(variants, assigns[:variant]),
            Map.fetch!(sizes, assigns[:size]),
            assigns[:errors] != [] && "input-error"
          ]
      )

    ~H"""
    <div class="form-control">
      <label :if={@label} class="label">
        <span class="label-text text-base-content">{@label}</span>
      </label>
      <input type={@type} id={@id} name={@name} value={@value} class={@class} {@rest} />
      <div :if={@errors != []} class="label">
        <span :for={msg <- @errors} class="label-text-alt text-error">{msg}</span>
      </div>
    </div>
    """
  end

  @doc """
  Renders a markdown-styled modal.

  ## Examples

      <.md_modal id="confirm-modal" show={@show_modal} on_cancel={JS.push("cancel")}>
        <h3 class="font-bold text-lg">Confirm action</h3>
        <p class="py-4">Are you sure you want to continue?</p>
        <div class="modal-action">
          <.md_button phx-click={JS.push("cancel")}>Cancel</.md_button>
          <.md_button variant="primary" phx-click={JS.push("confirm")}>Confirm</.md_button>
        </div>
      </.md_modal>
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, :any, default: nil
  attr :class, :string, default: nil
  attr :placement, :string, values: ~w(top middle bottom start end), default: "middle"
  slot :inner_block, required: true

  def md_modal(assigns) do
    placements = %{
      "top" => "modal-top",
      "middle" => "modal-middle",
      "bottom" => "modal-bottom",
      "start" => "modal-start",
      "end" => "modal-end"
    }

    assigns =
      assign(
        assigns,
        :class,
        assigns[:class] ||
          [
            "modal",
            assigns[:show] && "modal-open",
            Map.fetch!(placements, assigns[:placement])
          ]
      )

    ~H"""
    <div
      :if={@show}
      id={@id}
      class={@class}
      phx-click-away={@on_cancel}
      phx-key="escape"
      phx-keydown={@on_cancel}
    >
      <div class="modal-box bg-base-100 border border-base-content/20 rounded-none shadow-lg">
        <button
          :if={@on_cancel}
          type="button"
          phx-click={@on_cancel}
          class="btn btn-sm btn-square btn-ghost absolute right-2 top-2 text-base-content/60 hover:text-base-content"
          aria-label="close"
        >
          <.icon name="hero-x-mark" class="size-4" />
        </button>
        {render_slot(@inner_block)}
      </div>
      <div class="modal-backdrop bg-base-content/20" phx-click={@on_cancel}></div>
    </div>
    """
  end

  @doc """
  Renders a markdown-styled card component.

  ## Examples

      <.md_card>
        <:title>Card Title</:title>
        <p>Card content goes here</p>
      </.md_card>

      <.md_card variant="primary" size="lg">
        <:title>Large Primary Card</:title>
        <:body>
          <p>Card body content</p>
        </:body>
        <:actions>
          <.md_button>Action</.md_button>
        </:actions>
      </.md_card>
  """
  attr :class, :string, default: nil
  attr :variant, :string, values: ~w(neutral primary secondary accent), default: "neutral"
  attr :size, :string, values: ~w(xs sm md lg xl), default: "md"
  attr :border, :boolean, default: true

  slot :title, doc: "Card title slot"
  slot :body, doc: "Card body content slot"
  slot :actions, doc: "Card actions slot for buttons"
  slot :inner_block, doc: "Default slot for card content"

  def md_card(assigns) do
    variants = %{
      "neutral" => "bg-base-200",
      "primary" => "bg-primary/10",
      "secondary" => "bg-secondary/10",
      "accent" => "bg-accent/10"
    }

    sizes = %{
      "xs" => "w-32 h-32",
      "sm" => "w-40 h-40",
      "md" => "w-48 h-48",
      "lg" => "w-56 h-56",
      "xl" => "w-64 h-64"
    }

    assigns =
      assign(
        assigns,
        :class,
        assigns[:class] ||
          [
            "card rounded-none",
            Map.fetch!(variants, assigns[:variant]),
            Map.fetch!(sizes, assigns[:size]),
            assigns[:border] && "border border-base-content/20"
          ]
      )

    ~H"""
    <div class={@class}>
      <div class="card-body items-center text-center h-full flex flex-col justify-center">
        <h3 :if={@title != []} class="card-title">
          {render_slot(@title)}
        </h3>

        <div :if={@body != []}>
          {render_slot(@body)}
        </div>

        <div :if={@inner_block != []}>
          {render_slot(@inner_block)}
        </div>

        <div :if={@actions != []} class="card-actions justify-center mt-4">
          {render_slot(@actions)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a markdown-styled badge component.

  ## Examples

      <.md_badge>Default</.md_badge>
      <.md_badge variant="success">In Stock</.md_badge>
      <.md_badge variant="error" size="sm">Out of Stock</.md_badge>
      <.md_badge style="outline" variant="primary">Outlined</.md_badge>
  """
  attr :class, :string, default: nil

  attr :variant, :string,
    values: ~w(neutral primary secondary accent info success warning error),
    default: "neutral"

  attr :style, :string, values: ~w(default outline dash soft ghost), default: "default"
  attr :size, :string, values: ~w(xs sm md lg xl), default: "md"
  slot :inner_block, required: true

  def md_badge(assigns) do
    variants = %{
      "neutral" => "badge-neutral",
      "primary" => "badge-primary",
      "secondary" => "badge-secondary",
      "accent" => "badge-accent",
      "info" => "badge-info",
      "success" => "badge-success",
      "warning" => "badge-warning",
      "error" => "badge-error"
    }

    styles = %{
      "default" => nil,
      "outline" => "badge-outline",
      "dash" => "badge-dash",
      "soft" => "badge-soft",
      "ghost" => "badge-ghost"
    }

    sizes = %{
      "xs" => "badge-xs",
      "sm" => "badge-sm",
      "md" => "badge-md",
      "lg" => "badge-lg",
      "xl" => "badge-xl"
    }

    assigns =
      assign(
        assigns,
        :class,
        assigns[:class] ||
          [
            "badge rounded-none",
            Map.fetch!(variants, assigns[:variant]),
            Map.fetch!(styles, assigns[:style]),
            Map.fetch!(sizes, assigns[:size])
          ]
      )

    ~H"""
    <span class={@class}>
      {render_slot(@inner_block)}
    </span>
    """
  end
end
