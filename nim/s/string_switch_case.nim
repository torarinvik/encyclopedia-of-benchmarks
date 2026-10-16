const MaxTextLength = 1024
const MaxInputLength = MaxTextLength + 3

proc isSpace(value: int64): bool =
  value == 32 or (value >= 9 and value <= 13) or (value >= 28 and value <= 31)

proc isWord(value: int64): bool =
  (value >= 65 and value <= 90) or (value >= 97 and value <= 122) or
  (value >= 48 and value <= 57)

proc string_switch_case*(input: ptr UncheckedArray[int64], length: csize_t,
                         output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "string_switch_case".} =
  if input.isNil or length < 3 or length > MaxInputLength: return -1
  let mode = input[0]
  let separator = input[1]
  let textLength = input[2]
  if mode < 0 or mode > 8 or separator < 0 or separator > 127 or
     textLength < 0 or textLength > MaxTextLength or
     length != csize_t(textLength) + 3 or ((mode != 3 and mode != 4) and separator != 0): return -1
  for i in 0 ..< int(textLength):
    if input[i + 3] < 0 or input[i + 3] > 127: return -1

  var result: array[MaxTextLength, uint8]
  var used = 0
  if mode <= 2:
    var atWordStart = true
    for i in 0 ..< int(textLength):
      var value = input[i + 3]
      if not isWord(value):
        atWordStart = true
        continue
      if atWordStart:
        if value >= 97 and value <= 122: value -= 32
        atWordStart = false
      elif value >= 65 and value <= 90:
        value += 32
      result[used] = uint8(value)
      inc used
    if mode == 2:
      if used == 0:
        for value in "not valid string":
          result[used] = uint8(ord(value))
          inc used
      elif result[0] >= 65 and result[0] <= 90:
        result[0] += 32
  else:
    let upper = mode == 4 or mode == 6 or mode == 8
    let delimiter = uint8(if mode <= 4: separator elif mode <= 6: 95 else: 45)
    var groupHasWord = false
    var pendingSpace = false
    for i in 0 ..< int(textLength):
      var value = input[i + 3]
      if isSpace(value):
        if groupHasWord: pendingSpace = true
        continue
      if not isWord(value):
        groupHasWord = false
        pendingSpace = false
        continue
      if pendingSpace and groupHasWord:
        result[used] = delimiter
        inc used
      pendingSpace = false
      if upper and value >= 97 and value <= 122: value -= 32
      elif not upper and value >= 65 and value <= 90: value += 32
      result[used] = uint8(value)
      inc used
      groupHasWord = true
  if csize_t(used) > capacity or (used > 0 and output.isNil): return -2
  for i in 0 ..< used: output[i] = result[i]
  int64(used)
