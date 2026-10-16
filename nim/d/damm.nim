const MaxDigits = 256
const Table: array[100, int64] = [0, 3, 1, 7, 5, 9, 8, 6, 4, 2, 7, 0, 9, 2, 1, 5, 4, 8, 6, 3, 4, 2, 0, 6, 8, 7, 1, 3, 5, 9, 1, 7, 5, 0, 9, 8, 3, 4, 2, 6, 6, 1, 2, 3, 0, 4, 5, 9, 7, 8, 3, 6, 7, 4, 2, 0, 9, 5, 8, 1, 5, 8, 6, 9, 7, 2, 0, 1, 3, 4, 8, 9, 4, 5, 3, 6, 2, 0, 1, 7, 9, 4, 3, 8, 6, 1, 7, 2, 0, 5, 2, 5, 8, 1, 4, 3, 6, 7, 9, 0]

## Validate a complete sequence or compute its appended Damm check digit.
proc damm*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "damm".} =
  if input == nil or length < 3 or length > csize_t(MaxDigits + 2): return -1
  let mode = input[0]
  let n = input[1]
  if (mode != 0 and mode != 1) or n < 1 or n > MaxDigits or length != csize_t(n + 2): return -1
  var state = 0
  for index in 0 ..< int(n):
    let digit = input[index + 2]
    if digit < 0 or digit > 9: return -1
    state = int(Table[state * 10 + int(digit)])
  if mode == 0:
    if state == 0: return 1
    return 0
  int64(state)
