const CheckLetters = "TRWAGMYFPDXBNJZSQVHLCKE"

type I64Input = ptr UncheckedArray[int64]

proc is_spain_national_id*(input: I64Input, length: csize_t): int64
    {.cdecl, exportc: "is_spain_national_id".} =
  if input == nil or (length != 9 and length != 10): return -1
  for index in 0 ..< int(length):
    if input[index] < 0 or input[index] > 127: return -1
  if length == 10 and input[8] != 45: return -1
  var number = 0'i64
  for index in 0 ..< 8:
    if input[index] < 48 or input[index] > 57: return -1
    number = number * 10 + input[index] - 48
  var letter = input[int(length) - 1]
  if letter >= 97 and letter <= 122: letter -= 32
  if letter < 65 or letter > 90: return -1
  if letter == int64(ord(CheckLetters[int(number mod 23)])): 1 else: 0
