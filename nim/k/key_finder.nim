const MaxTextLength = 256'i64
const MaxInputLength = 258
const WordBank = [
  "I ", "You ", "We ", "They ", "He ", "She ", "It ", " the ",
  "The ", " of ", " is ", "Is ", " am ", "Am ", " are ", "Are ",
  " have ", "Have ", " has ", "Has ", " may ", "May ", " be ", "Be "
]

proc shiftAsciiLetter(code: int64, key: int64): int64 =
  if code >= 65 and code <= 90: return 65 + (code - 65 + key) mod 26
  if code >= 97 and code <= 122: return 97 + (code - 97 + key) mod 26
  code

proc key_finder*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "key_finder".} =
  if input == nil or length < csize_t(1) or length > csize_t(MaxInputLength): return -1
  let textLengthValue = input[0]
  if textLengthValue < 0 or textLengthValue > MaxTextLength: return -1
  let textLength = int(textLengthValue)
  if int(length) != textLength + 1: return -1
  for index in 0 ..< textLength:
    let code = input[index + 1]
    if code < 32 or code > 126 or (code >= 48 and code <= 57): return -1

  for key in 0 ..< 26:
    let keyValue = int64(key)
    for start in 0 ..< textLength:
      for phrase in WordBank:
        if start + phrase.len > textLength: continue
        var offset = 0
        while offset < phrase.len and
            shiftAsciiLetter(input[start + offset + 1], keyValue) == int64(ord(phrase[offset])):
          inc offset
        if offset == phrase.len: return keyValue
  0
