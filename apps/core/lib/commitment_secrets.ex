defmodule Volta.Core.CommitmentSecrets do
  use Bitwise

  def pubkey_from_points(basepoint, per_commitment_point) do
    
  end

  def privkey_from_points(basepoint_secret, per_commitment_point) do
    
  end

  def revocation_pubkey(revocation_basepoint, per_commitment_point) do
    
  end

  def revocation_privkey(recovation_basepoint_secret, revocation_basepoint, per_commitment_point) do
    
  end

  def new_seed() do
    :crypto.strong_rand_bytes(32)
  end

  def starting_index(), do: 281474976710655

  def commitment(seed, index) do
    b = 1 <<< 47
    # b will be used as a mask, and after each use
    # it will be shifted right until it is zero.
    # 1 <<< 47 should yield 48 total iterations.
    commitment(seed, index, b)
  end

  defp commitment(p, i, b) when b > 0 do
    if (b &&& i) > 0 do # if B set in I
      p = :crypto.exor(p, <<b::unsigned-little-size(256)>>) # flip(B) in P
      p = :crypto.hash(:sha256, p)
      commitment(p, i, b >>> 1)
    else
      commitment(p, i, b >>> 1)
    end
  end

  defp commitment(p, _i, _b) do
    p
  end

end
