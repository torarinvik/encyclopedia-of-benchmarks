const MaxStates = 64
const MaxInputLength = MaxStates + 2

proc sum_over_subsets_zeta_transform*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "sum_over_subsets_zeta_transform".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let bitCount = input[0]
  if bitCount < 0 or bitCount > 6: return -1
  let stateCount = 1 shl int(bitCount)
  if length != csize_t(stateCount + 1): return -1

  var transformed: array[MaxStates, int64]
  for mask in 0 ..< stateCount:
    let value = input[mask + 1]
    if value < 0 or value > 1_000_000: return -1
    transformed[mask] = value

  for bitIndex in 0 ..< int(bitCount):
    let bit = 1 shl bitIndex
    for mask in 0 ..< stateCount:
      if (mask and bit) != 0:
        transformed[mask] += transformed[mask xor bit]

  var checksum = 0'i64
  for mask in 0 ..< stateCount:
    checksum += int64(mask + 1) * transformed[mask]
  checksum
