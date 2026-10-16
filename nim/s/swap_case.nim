const MaxInputLength = 4096

proc swap_case*(input: ptr UncheckedArray[int64], length: csize_t,
                output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "swap_case".} =
  if length > MaxInputLength: return -1
  if length > 0 and input.isNil: return -1
  for i in 0 ..< int(length):
    if input[i] < 0 or input[i] > 127: return -1
  if length > capacity or (length > 0 and output.isNil): return -2
  for i in 0 ..< int(length):
    var value = input[i]
    if value >= 65 and value <= 90: value += 32
    elif value >= 97 and value <= 122: value -= 32
    output[i] = uint8(value)
  int64(length)
