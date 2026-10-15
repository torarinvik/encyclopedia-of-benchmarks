## Check bracket nesting with a bounded stack.
proc valid_parentheses*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "valid_parentheses".} =
  if length > 256 or (length > 0 and input.isNil): return -1
  for index in 0 ..< int(length):
    let value = input[index]
    if value notin [40'i64, 41, 91, 93, 123, 125]: return -1
  var stack: array[256, uint8]
  var top = 0
  for index in 0 ..< int(length):
    let value = uint8(input[index])
    if value == uint8(ord('(')) or value == uint8(ord('[')) or value == uint8(ord('{')):
      stack[top] = value
      inc top
    else:
      if top == 0: return 0
      dec top
      let expected = if value == uint8(ord(')')): uint8(ord('('))
                     elif value == uint8(ord(']')): uint8(ord('['))
                     else: uint8(ord('{'))
      if stack[top] != expected: return 0
  if top == 0: 1 else: 0
