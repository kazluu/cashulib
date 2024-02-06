defmodule Cashu.Proof do
  @moduledoc """
  NUT-00: Proof
  A Proof is also called an input and is generated by Alice from a BlindedSignature it received. An array [Proof] is called Proofs. Alice sends Proofs to Bob for melting tokens. Serialized Proofs can also be sent from Alice to Carol. Upon receiving the token, Carol deserializes it and requests a swap from Bob to receive new Proofs.
  """
  alias Cashu.{BDHKE, Error, Validator}
  alias Bitcoinex.Secp256k1.Point

  @derive Jason.Encoder
  defstruct [:amount, :id, :secret, :C]

  def new(c_, secret, amount, mint_pubkey) do
    case BDHKE.generate_proof(c_, secret, mint_pubkey) do
      {:ok, %Point{} = c} ->
        # id = get_keyset_id()
        hex_c = Point.serialize_public_key(c)
        %__MODULE__{amount: amount, id: nil, secret: secret, C: hex_c}

      {:error, reason} ->
        Error.new(reason)
    end
  end

  def validate(%__MODULE__{amount: amount, id: id, secret: secret, C: c} = proof) do
    with {:ok, _} <- Validator.validate_amount(amount),
         {:ok, _} <- Validator.validate_id(id),
         {:ok, _} <- Validator.validate_secret(secret),
         {:ok, _} <- Validator.validate_c(c) do
      {:ok, proof}
    else
      {:error, reason} -> Error.new(reason)
    end
  end

  def validate(_), do: {:error, "Invalid %Proof{} struct found."}

  def encode(%__MODULE__{} = msg) do
    case Jason.encode(msg) do
      {:ok, encoded} ->
        {:ok, encoded}

      {:error, reason} ->
        Error.new(reason)
    end
  end
end
