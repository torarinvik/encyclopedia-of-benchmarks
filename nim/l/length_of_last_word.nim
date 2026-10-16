proc length_of_last_word*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "length_of_last_word".} =
  if input.isNil or length < 1 or length > 129: return -1
  if input[0] < 0 or input[0] > 128 or length != csize_t(input[0]) + 1: return -1
  var index = int(input[0])
  while index > 0 and input[index] == 32: dec index
  var wordLength = 0'i64
  while index > 0 and input[index] != 32:
    if input[index] < 0 or input[index] > 255: return -1
    inc wordLength
    dec index
  for i in 1 ..< int(length):
    if input[i] < 0 or input[i] > 255: return -1
  wordLength
