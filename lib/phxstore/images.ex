defmodule Phxstore.Images do
  alias Phxstore.Repo
  alias Phxstore.Files.Image

  @storage Application.compile_env(:phxstore, :file_storage)

  @doc """
  Creates a new image.

  Saves the image file using app file storage.
  """
  def create_image(attrs) do
    case %Image{}
         |> Image.changeset(attrs)
         |> Repo.insert() do
      {:ok, image} ->
        # This is a temporary logic
        @storage.save_file(image)
        {:ok, image}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
