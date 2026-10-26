const MaxOutput = 1544

proc put(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc three_dimensional_moment_curve*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "three_dimensional_moment_curve".} =
  if input.isNil or length != 1 or input[0] < 0 or input[0] > 64: return -1
  let n = int(input[0]); let bytes = 8 * (1 + 3 * n)
  if output.isNil or capacity < csize_t(bytes): return -2
  var staged: array[MaxOutput, uint8]
  put(addr staged[0], 0, int64(n))
  for i in 1..n:
    let x = int64(i); let offset = 8 * (1 + 3 * (i - 1))
    put(addr staged[0], offset, x); put(addr staged[0], offset + 8, x * x); put(addr staged[0], offset + 16, x * x * x)
  for i in 0..<bytes: output[i] = staged[i]
  int64(bytes)
