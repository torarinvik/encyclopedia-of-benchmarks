proc grow_only_set*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "grow_only_set".} =
  if values == nil or length < 1 or length > 25:
    return -1
  let countValue = values[0]
  if countValue < 0 or countValue > 12 or length != csize_t(1 + 2 * countValue):
    return -1
  var left = 0'u64
  var right = 0'u64
  var answers = 0'u64
  var queryCount = 0
  for index in 0 ..< int(countValue):
    let opcode = values[1 + 2 * index]
    let argument = values[2 + 2 * index]
    if opcode < 0 or opcode > 7:
      return -1
    if opcode <= 3:
      if argument < 0 or argument > 15:
        return -1
    elif argument != 0:
      return -1
    let bit = if opcode <= 3: (1'u64 shl int(argument)) else: 0'u64
    if opcode == 0:
      left = left or bit
    elif opcode == 1:
      right = right or bit
    elif opcode == 2:
      if (left and bit) != 0: answers = answers or (1'u64 shl queryCount)
      inc queryCount
    elif opcode == 3:
      if (right and bit) != 0: answers = answers or (1'u64 shl queryCount)
      inc queryCount
    elif opcode == 4:
      if (left and right) == left: answers = answers or (1'u64 shl queryCount)
      inc queryCount
    elif opcode == 5:
      if (left and right) == right: answers = answers or (1'u64 shl queryCount)
      inc queryCount
    elif opcode == 6:
      left = left or right
    else:
      right = right or left
  int64(answers or (left shl 12) or (right shl 28) or (uint64(queryCount) shl 44))
