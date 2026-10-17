type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc isRemoved(value: int64, input: I64Input, n: int, by: int): bool =
  if by == 0: return true
  for key in (n - by) ..< n:
    if value == input[2 + key]: return true
  return false

proc putI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc shorten_vector*(input: I64Input, length: csize_t, output: U8Output, capacity: csize_t): int64
    {.cdecl, exportc: "shorten_vector".} =
  if input == nil or length < 2 or length > 67: return -1
  let rawN = input[0]
  let rawBy = input[1]
  if rawN < 0 or rawN > 64 or rawBy < 0 or rawBy > rawN: return -1
  let n = int(rawN)
  let by = int(rawBy)
  if length != csize_t(2 + n): return -1
  for i in 0..<n:
    if input[2 + i] < -1_000_000 or input[2 + i] > 1_000_000: return -1

  var survivorCount = 0
  for i in 0..<n:
    if not isRemoved(input[2 + i], input, n, by): inc survivorCount
  let bytes = survivorCount * 8
  if output == nil or capacity < csize_t(bytes): return -2

  var written = 0
  for i in 0..<n:
    let value = input[2 + i]
    if not isRemoved(value, input, n, by):
      putI64Le(output, written * 8, value)
      inc written
  int64(bytes)
