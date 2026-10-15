proc snake_case_to_camel_pascal_case*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "snake_case_to_camel_pascal_case".} =
  if input == nil or length < 2 or length > 257: return -1
  if input[0] != 0 and input[0] != 1: return -1

  let inputLength = int(length) - 1
  var outputLength = 0
  for i in 0 ..< inputLength:
    let value = input[i + 1]
    if value == 95:
      if i == 0 or i + 1 == inputLength or input[i] == 95: return -1
    elif not ((value >= 97 and value <= 122) or (value >= 48 and value <= 57)):
      return -1
    else:
      inc outputLength
  if int(capacity) < outputLength or output == nil: return -2

  var capitalize = input[0] == 1
  var position = 0
  for i in 0 ..< inputLength:
    var value = input[i + 1]
    if value == 95:
      capitalize = true
      continue
    if capitalize and value >= 97 and value <= 122: value -= 32
    output[position] = uint8(value)
    inc position
    capitalize = false
  int64(outputLength)
