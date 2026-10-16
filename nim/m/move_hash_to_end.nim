const MaxTextLength = 256

proc move_hash_to_end*(values: ptr UncheckedArray[int64], length: csize_t,
                       output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "move_hash_to_end".} =
  if values.isNil or length < 1 or length > 258: return -1
  let textLength = values[0]
  if textLength < 0 or textLength > MaxTextLength or length != csize_t(textLength + 1): return -1
  for i in 0 ..< int(textLength):
    if values[i + 1] < 0 or values[i + 1] > 127: return -1
  let n = int(textLength)
  if capacity < csize_t(n) or (n > 0 and output.isNil): return -2
  var position = 0
  for i in 0 ..< n:
    if values[i + 1] != 35:
      output[position] = uint8(values[i + 1])
      inc position
  while position < n:
    output[position] = uint8(ord('#'))
    inc position
  int64(n)
