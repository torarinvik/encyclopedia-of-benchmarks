type I64Input = ptr UncheckedArray[int64]

proc lowercaseAsciiLetter(value: int64): int64 =
  if value >= 65 and value <= 90: value + 32 else: value

proc count_letters*(input: I64Input, length: csize_t): int64 {.cdecl, exportc: "count_letters".} =
  if input == nil or length < 2 or input[1] < 0 or input[1] > 256: return -1
  let textLength = int(input[1])
  if length != csize_t(textLength + 2): return -1
  let query = lowercaseAsciiLetter(input[0])
  if query < 97 or query > 122: return -1
  var count = 0'i64
  for index in 0 ..< textLength:
    let value = input[index + 2]
    if not ((value >= 97 and value <= 122) or (value >= 65 and value <= 90)): return -1
    if lowercaseAsciiLetter(value) == query: inc count
  count
