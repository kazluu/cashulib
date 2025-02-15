defmodule Cashu.Validator do
  @moduledoc """
  Validator functions for cashu data fields.

  All functions in this module should return an :ok or :error tuple.
  Cashu.Error return values are constructed upstream, usually from these error values.
  """

  def validate_amount(amount) when is_integer(amount) and amount >= 0, do: {:ok, amount}
  def validate_amount(_), do: {:error, "Invalid amount"}

  def validate_id(id) when is_binary(id), do: {:ok, id}
  def validate_id(_), do: {:error, "Invalid ID"}

  def validate_b_(b_) when is_binary(b_), do: {:ok, b_}
  def validate_b_(_), do: {:error, "Invalid blinded point B_"}

  def validate_secret(secret) when is_binary(secret), do: {:ok, secret}
  def validate_secret(_), do: {:error, "Invalid secret: must be a binary"}

  def validate_c(c) when is_binary(c), do: {:ok, c}
  def validate_c(_), do: {:error, "Invalid unblinded point C"}

  def validate_c_(c_) when is_binary(c_), do: {:ok, c_}
  def validate_c_(_), do: {:error, "Invalid c_"}

  def validate_unit("sat"), do: {:ok, "sat"}
  def validate_unit(_), do: {:error, "Invalid currency unit: sats only bb"}

  def validate_memo(memo) when is_binary(memo), do: {:ok, memo}
  def validate_memo(_), do: {:error, "Invalid memo: not a string"}

  def validate_key_len(key) when byte_size(key) > 33 do
    if String.valid?(key) do
      case Base.decode16(key, case: :lower) do
        {:ok, bytes} -> validate_key_prefix(bytes)
        :error -> {:error, :invalid_key}
      end
    end
  end

  def validate_key_len(<<4::8, _::binary>>), do: {:error, :uncompressed_key}

  def validate_key_len(<<prefix::8, rest::binary>> = key) when byte_size(rest) == 32 do
    if prefix in [2, 3] do
      {:ok, key}
    else
      {:error, :invalid_key}
    end
  end

  def validate_key_len(_), do: {:error, :invalid_key}

  defp validate_key_prefix(<<2, rest::binary>> = key) when byte_size(rest) == 32, do: {:ok, key}
  defp validate_key_prefix(<<3, rest::binary>> = key) when byte_size(rest) == 32, do: {:ok, key}
  defp validate_key_prefix(<<4, rest::binary>>) when byte_size(rest) == 64, do: {:error, :uncompressed_key}
  defp validate_key_prefix(_), do: {:error, :invalid_key}

  def validate_url(mint_url) do
    case URI.parse(mint_url) do
      %URI{host: nil} -> {:error, "invalid mint URL"}
      %URI{scheme: "https", host: host} -> {:ok, host}
      %URI{scheme: nil} -> {:error, "no http scheme provided"}
      _ -> {:error, "could not parse mint URL"}
    end
  end

  def validate_keyset_id("00" <> keyset_id) do
    case String.length(keyset_id) == 14 do
      true -> {:ok, keyset_id}
      false -> {:error, "Invalid keyset ID length, got: #{keyset_id}"}
    end
  end

  def validate_keyset_id(keyset_id),
    do: {:error, "Invalid Keyset ID version prefix, got: #{keyset_id}"}

  @doc """
  Validate a list of structs and collect the results into a map of ok/error tuples.
  We do this often in Cashu: validate a list of Proofs, a list of BlindedSignatures, Tokens, etc.
  We usually want to reject the whole set if an error occurs in one of them.
  """
  def validate_list(list, validate_fun, acc \\ %{ok: [], error: []})
  def validate_list([], _validate_fun, %{ok: ok_proofs, error: []}), do: {:ok, ok_proofs}
  def validate_list([], _validate_fun, %{ok: _, error: errors}), do: {:error, errors}

  def validate_list([head | tail], validate_fun, acc) do
    new_acc = validate_fun.(head) |> collect_results(acc)
    validate_list(tail, new_acc)
  end

  # an accumulator map with :ok and :error keys and a list as values
  def collect_results({key, value}, acc) do
    acc_val = Map.get(acc, key)
    new_list = [value | acc_val]
    Map.put(acc, key, new_list)
  end
end
