defmodule FunJson do

  def decode_json(json_string), do: json_string |> FunJson.Parser.parse

  def decode_json_from_file(path) do
    case File.read(path) do
      {:error, reason} -> {:error, reason}
      {:ok, json_string} -> decode_json(json_string)
    end
  end

end
