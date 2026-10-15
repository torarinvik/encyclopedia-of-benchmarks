## Emit a bounded geometric term sequence as little-endian binary64 values.
proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc geometric_series*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "geometric_series".} =
  if input.isNil or length != 3: return -1
  if input[0] < 0 or input[0] > 16 or input[1] < 1 or input[1] > 8 or input[2] < 1 or input[2] > 4: return -1
  let n = int(input[0])
  if capacity < csize_t(n * 8) or (n > 0 and output.isNil): return -2
  var term = float64(input[1]); let ratio = float64(input[2])
  for index in 0 ..< n:
    putF64Le(output, index * 8, term)
    term *= ratio
  int64(n * 8)
