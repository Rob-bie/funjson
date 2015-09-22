defmodule FunJson.Lexer do

  # Breaks up JSON string into tokens.
  # Charlist implementation.

  def tokenize(json_string) do
    json_string
    |> String.to_char_list
    |> tokenize([], [])

  catch
    {:error, message} -> {:error, message}
  end

  defp tokenize([], _, tkns), do: Enum.reverse(tkns)

  # Accept braces/brackets
  defp tokenize([c=?\{ |rest], tkn_acc, tkns) do
    tokenize(ignore_ws(rest), tkn_acc, [c|tkns])
  end

  defp tokenize([c=?\} |rest], tkn_acc, tkns) do
    tokenize(ignore_ws(rest), tkn_acc, [c|tkns])
  end

  defp tokenize([c=?\[ |rest], tkn_acc, tkns) do
    tokenize(ignore_ws(rest), tkn_acc, [c|tkns])
  end

  defp tokenize([c=?\] |rest], tkn_acc, tkns) do
    tokenize(ignore_ws(rest), tkn_acc, [c|tkns])
  end 

  # Accept commas/colons
  defp tokenize([c=?\, |rest], tkn_acc, tkns) do
    tokenize(ignore_ws(rest), tkn_acc, [c|tkns])
  end

  defp tokenize([c=?\: |rest], tkn_acc, tkns) do
    tokenize(ignore_ws(rest), tkn_acc, [c|tkns])
  end

  # Jump to string state
  defp tokenize([?\" |rest], tkn_acc, tkns) do
    tokenize_string(rest, tkn_acc, tkns)
  end

  # Jump to number state
  defp tokenize([?-, d|rest], tkn_acc, tkns) when d in ?0..?9 do
    tokenize_number(rest, [d, ?- |tkn_acc], tkns)
  end

  defp tokenize([d|rest], tkn_acc, tkns) when d in ?0..?9 do
    tokenize_number(rest, [d|tkn_acc], tkns)
  end

  # Other literals
  defp tokenize([?t, ?r, ?u, ?e |rest], tkn_acc, tkns) do
    tokenize(ignore_ws(rest), tkn_acc, [true|tkns])
  end

  defp tokenize([?f, ?a, ?l, ?s, ?e |rest], tkn_acc, tkns) do
    tokenize(ignore_ws(rest), tkn_acc, [false|tkns])
  end

  defp tokenize([?n, ?u, ?l, ?l |rest], tkn_acc, tkns) do
    tokenize(ignore_ws(rest), tkn_acc, [nil|tkns])
  end

  defp tokenize(invalid, _, _) do
    bad_literal = Enum.take_while(invalid, &(!(&1 in '{}[]:,\"'))) |> to_string
    message = "Expecting literal, got: <#{bad_literal}>"
    throw({:error, message})
  end

  # Handle escape sequences
  defp tokenize_string([?\\, q=?\" |rest], tkn_acc, tkns) do
    tokenize_string(rest, [q|tkn_acc], tkns)
  end

  defp tokenize_string([?\\, fs=?/ |rest], tkn_acc, tkns) do
    tokenize_string(rest, [fs|tkn_acc], tkns)
  end

  defp tokenize_string([?\\, ?n |rest], tkn_acc, tkns) do
    tokenize_string(rest, [?\n |tkn_acc], tkns)
  end

  defp tokenize_string([?\\, ?r |rest], tkn_acc, tkns) do
    tokenize_string(rest, [?\r |tkn_acc], tkns)
  end

  defp tokenize_string([?\\, ?t |rest], tkn_acc, tkns) do
    tokenize_string(rest, [?\t |tkn_acc], tkns)
  end

  defp tokenize_string([?\\, ?\\ |rest], tkn_acc, tkns) do
    tokenize_string(rest, [?\\ |tkn_acc], tkns)
  end

  # End of string found
  defp tokenize_string([?\" |rest], tkn_acc, tkns) do
    tokenize(ignore_ws(rest), [], [list_to_str(tkn_acc)|tkns])
  end

  defp tokenize_string([c|rest], tkn_acc, tkns) do
    tokenize_string(rest, [c|tkn_acc], tkns)
  end

  defp tokenize_number([c|rest], tkn_acc, tkns) when c in ?0..?9 do
    tokenize_number(rest, [c|tkn_acc], tkns)
  end

  defp tokenize_number([c=?. |rest], tkn_acc, tkns) do
    tokenize_fract(rest, [c|tkn_acc], tkns)
  end

  defp tokenize_number(chars, tkn_acc, tkns) do
    number = tkn_acc |> list_to_str |> String.to_integer
    tokenize(ignore_ws(chars), [], [number|tkns])
  end

  defp tokenize_fract([c|rest], tkn_acc, tkns) when c in ?0..?9 do
    tokenize_fract(rest, [c|tkn_acc], tkns)
  end

  defp tokenize_fract([c|rest], tkn_acc, tkns) when c in [?e, ?E] do
    tokenize_exp(rest, [c|tkn_acc], tkns)
  end

  defp tokenize_fract(chars, tkn_acc, tkns) do
    number = tkn_acc |> list_to_str |> String.to_float
    tokenize(ignore_ws(chars), [], [number|tkns])
  end

  defp tokenize_exp([c|rest], tkn_acc, tkns) when c in [?+, ?-] do
    fract_digits(rest, [c|tkn_acc], tkns)
  end

  defp tokenize_exp([c|rest], tkn_acc, tkns) when c in ?0..?9 do
    fract_digits(rest, [c|tkn_acc], tkns)
  end

  # Extract rest of fractional digits
  defp fract_digits([c|rest], tkn_acc, tkns) when c in ?0..?9 do
    fract_digits(rest, [c|tkn_acc], tkns)
  end

  defp fract_digits(chars, tkn_acc, tkns) do
    number = tkn_acc |> list_to_str |> String.to_float
    tokenize(chars, [], [number|tkns])
  end

  # Ignore whitespace
  defp ignore_ws([c|rest]) when c in '\n\r\t\s' do
    ignore_ws(rest)
  end

  defp ignore_ws(rest), do: rest

  # Charlist -> String
  defp list_to_str(list), do: list |> Enum.reverse |> to_string

end
