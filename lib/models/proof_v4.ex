defmodule Cashu.ProofV4 do
  @moduledoc """
  NUT-00: V4 Proof
  A Proof is also called an input and is generated by Alice from a BlindedSignature it received. An array [Proof] is called Proofs. Alice sends Proofs to Bob for melting tokens. Serialized Proofs can also be sent from Alice to Carol. Upon receiving the token, Carol deserializes it and requests a swap from Bob to receive new Proofs.
  """
  alias Cashu.{BDHKE, Error, Validator}
  alias Bitcoinex.Secp256k1.Point

  @derive Jason.Encoder
  defstruct keyset_id: "", amount: 0, secret: "", signature: "", witness: nil, dleq_proof: nil

  @type t :: %{
          id: String.t(),
          amount: pos_integer(),
          secret: String.t(),
          signature: String.t(),
          dleq_proof: list(Cashu.DLEQ.t())
        }

  def new(), do: %__MODULE__{}
  def new(params) when is_list(params), do: struct!(__MODULE__, params)
  def new(params) when is_map(params), do: Map.to_list(params) |> new()

  def new(c_, secret, amount, keyset_id, mint_pubkey) do
    case BDHKE.generate_proof(c_, secret, mint_pubkey) do
      {:ok, %Point{} = c} ->
        hex_c = Point.serialize_public_key(c)
        new(amount: amount, id: keyset_id, secret: secret, C: hex_c)

      {:error, reason} ->
        Error.new(reason)
    end
  end

  def validate(%{valid?: true} = changeset), do: {:ok, changeset}
  def validate(%{valid?: false}), do: {:error, :invalid_proof}

  def validate_proof_list(list), do: Validator.validate_list(list, &validate/1)

  def from_cbor_serialized_map(%{"a" => amount, "i" => keyset_id, "s" => secret, "c" => signature}) do
    new(
      amount: amount,
      keyset_id: :binary.encode_hex(keyset_id, :lowercase),
      secret: secret,
      signature: :binary.encode_hex(signature, :lowercase)
    )
  end
end
