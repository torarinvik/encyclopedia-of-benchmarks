proc camel_case_to_snake_case*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "camel_case_to_snake_case".} =
  if length == 0 or length > 256 or input == nil: return -1

  var outputLength = 0
  for i in 0 ..< int(length):
    let value = input[i]
    if value >= 65 and value <= 90:
      if i > 0: inc outputLength
    elif value < 97 or value > 122:
      return -1
    inc outputLength
  if int(capacity) < outputLength or output == nil: return -2

  var position = 0
  for i in 0 ..< int(length):
    let value = input[i]
    if value >= 65 and value <= 90:
      if i > 0:
        output[position] = uint8(ord('_'))
        inc position
      output[position] = uint8(value + 32)
    else:
      output[position] = uint8(value)
    inc position
  int64(outputLength)
