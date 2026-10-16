## Encrypt ASCII letters with a repeating decimal-digit Gronsfeld key.
proc gronsfeld*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "gronsfeld".} =
  if input == nil or length < 2 or length > 321: return -1
  var separator = 0
  while separator < int(length) and input[separator] != 0: inc separator
  if separator == int(length): return -1
  let textLength = separator
  let keyLength = int(length) - separator - 1
  if textLength > 256 or keyLength < 1 or keyLength > 64: return -1

  for index in 0 ..< textLength:
    if input[index] < 1 or input[index] > 127: return -1
  for index in 0 ..< keyLength:
    let value = input[separator + 1 + index]
    if value < 48 or value > 57: return -1
  if csize_t(textLength) > outputCapacity or (textLength > 0 and output == nil): return -2

  var keyIndex = 0
  for index in 0 ..< textLength:
    let value = input[index]
    var mapped = value
    if value >= 65 and value <= 90:
      let shift = input[separator + 1 + keyIndex mod keyLength] - 48
      mapped = 65 + (value - 65 + shift) mod 26
      inc keyIndex
    elif value >= 97 and value <= 122:
      let shift = input[separator + 1 + keyIndex mod keyLength] - 48
      mapped = 97 + (value - 97 + shift) mod 26
      inc keyIndex
    output[index] = uint8(mapped)
  int64(textLength)
