defmodule FunJson.Parser do

  # Converts tokens to a map, only maps are supported
  # as of now.

  def parse(json_string) do
    lex_result = json_string |> FunJson.Lexer.tokenize
    case lex_result do
      {:error, message} -> {:error, message}
      _ -> start_parse(lex_result)
    end

  catch
    {:error, message} -> {:error, message}

  end

  # Object start
  defp start_parse([?\{ |rest]) do
    {_, result} = parse_object(rest, %{})
    result
  end

  # Array start
  defp start_parse([?\[ |rest]) do
    {_, result} = parse_array(rest, [])
    result
  end

  # Other literal start, simply returns the literal
  defp start_parse(literal), do: hd(literal)

  # Parse an object
  defp parse_object([?, |rest], acc) do
    parse_object(rest, acc)
  end

  defp parse_object([key, ?:, _|_], _) when not is_binary(key) do
    message = "Keys must be of type string, got: <#{key}>"
    throw({:error, message})
  end

  defp parse_object([key, ?:, ?\{ |rest], acc) do
    {rest, obj} = parse_object(rest, %{})
    parse_object(rest, Dict.put(acc, key, obj))
  end

  defp parse_object([key, ?:, ?\[ |rest], acc) do
    {rest, array} = parse_array(rest, [])
    parse_object(rest, Dict.put(acc, key, array))
  end

  defp parse_object([key, ?:, val|rest], acc) do
    parse_object(rest, Dict.put(acc, key, val))
  end

  defp parse_object([?\} |rest], acc), do: {rest, acc}

  defp parse_object([key, bad_token|_], _) do
    message = "Expecting colon after key <#{key}> but got: <#{bad_token}>"
    throw({:error, message})
  end

  defp parse_object(_, _) do
    message = "Dangling open brace"
    throw({:error, message})
  end

  # Parse an array
  defp parse_array([?, |rest], acc) do
    parse_array(rest, acc)
  end

  defp parse_array([?\{ |rest], acc) do
    {rest, obj} = parse_object(rest, %{})
    parse_array(rest, [obj|acc])
  end

  defp parse_array([?\[ |rest], acc) do
    {rest, array} = parse_array(rest, [])
    parse_array(rest, [array|acc])
  end

  defp parse_array([?\] |rest], acc), do: {rest, Enum.reverse(acc)}

  defp parse_array(_, _) do
    message = "Dangling open bracket"
    throw({:error, message})
  end

  defp parse_array([literal|rest], acc) do
    parse_array(rest, [literal|acc])
  end

end
