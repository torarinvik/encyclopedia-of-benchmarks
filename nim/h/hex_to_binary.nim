proc hexValue(value: int64): int =
  if value >= 48 and value <= 57: return int(value - 48)
  if value >= 65 and value <= 70: return int(value - 65 + 10)
  if value >= 97 and value <= 102: return int(value - 97 + 10)
  -1

proc hex_to_binary*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "hex_to_binary".} =
  if length > 256 or (length != 0 and values.isNil): return -1
  for index in 0 ..< int(length):
    if hexValue(values[index]) < 0: return -1

  let required = int(length) * 4
  if output.isNil or int(capacity) < required: return -2
  for index in 0 ..< int(length):
    let digit = hexValue(values[index])
    for bit in 0 ..< 4:
      output[index * 4 + bit] = (if ((digit shr (3 - bit)) and 1) == 1: uint8('1') else: uint8('0'))
  int64(required)
