defmodule Phxstore.Files.Storages.Test do
  def save_file(_path, _id, filename) do
    filename
  end

  def get_file_link(filename) do
    filename
  end

  def delete_file(_path) do
  end
end
