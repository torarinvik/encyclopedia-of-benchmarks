## Check (), [], and {} nesting; ignore other character codes.
proc balanced_parentheses*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "balanced_parentheses".} =
  if length > 4096: return -1
  var stack: array[4096, int64]
  var top = 0
  var index = 0
  while index < int(length):
    let value = values[index]
    if value == 40 or value == 91 or value == 123:
      stack[top] = value
      inc top
    elif value == 41 or value == 93 or value == 125:
      if top == 0: return 0
      dec top
      let opener = stack[top]
      if (value == 41 and opener != 40) or (value == 93 and opener != 91) or (value == 125 and opener != 123):
        return 0
    inc index
  if top == 0: 1 else: 0
