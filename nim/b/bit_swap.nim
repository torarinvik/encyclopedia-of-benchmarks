## Swap two 0-based bits in a signed 32-bit value.
proc bit_swap*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bit_swap".} =
  if length != 3 or values == nil: return -2_147_483_649'i64
  let data = values[0]
  let posA = values[1]
  let posB = values[2]
  if data < -2_147_483_648'i64 or data > 2_147_483_647'i64 or posA < 0 or posA >= 32 or posB < 0 or posB >= 32:
    return -2_147_483_649'i64
  var bits = data and 4_294_967_295'i64
  let maskA = 1'i64 shl int(posA)
  let maskB = 1'i64 shl int(posB)
  let bitA = (bits shr int(posA)) and 1
  let bitB = (bits shr int(posB)) and 1
  if bitA != bitB: bits = bits xor maskA xor maskB
  if bits >= 2_147_483_648'i64: return bits - 4_294_967_296'i64
  bits
