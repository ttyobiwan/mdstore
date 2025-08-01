defmodule Phxstore.Files.Storages.Local do
  @dir "priv/static/uploads"

  @doc """
  Save file using local file system.
  """
  def save_file(path, id, filename) do
    filename = "#{id}.#{get_extension(filename)}"
    dest = Path.join(@dir, filename)

    with :ok <- dest |> Path.dirname() |> File.mkdir_p(),
         :ok <- File.cp(path, dest) do
      {:ok, filename}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get link to locally stored file.
  """
  def get_file_link(filename) do
    Path.join("/uploads", filename)
  end

  @doc """
  Delete file from the local file system.
  """
  def delete_file(filename) do
    @dir
    |> Path.join(filename)
    |> File.rm()
  end

  defp get_extension(filename) do
    filename
    |> Path.extname()
    |> String.trim_leading(".")
  end
end
