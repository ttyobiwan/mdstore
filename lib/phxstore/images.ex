defmodule Phxstore.Images do
  alias Phxstore.Repo
  alias Phxstore.Files.Image

  @storage Application.compile_env(:phxstore, :file_storage)

  @doc """
  Creates a new image.

  Saves the image file using app file storage.
  """
  def create_image(path, id, filename) do
    with {:ok, filename} <- @storage.save_file(path, id, filename),
         {:ok, image} <-
           %Image{}
           |> Image.changeset(%{name: filename})
           |> Repo.insert() do
      {:ok, image}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Gets a link to the image.
  """
  def get_image_link(image) do
    @storage.get_file_link(image.name)
  end

  @doc """
  Deletes the image and the corresponding file.
  """
  def delete_image(image) do
    with :ok <- @storage.delete_file(image.name),
         {:ok, image} <- Repo.delete(image) do
      {:ok, image}
    end
  end
end
