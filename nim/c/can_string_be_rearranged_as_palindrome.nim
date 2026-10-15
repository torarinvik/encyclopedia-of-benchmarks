## Can lowercase ASCII letters be rearranged into a palindrome?
proc can_string_be_rearranged_as_palindrome*(text: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "can_string_be_rearranged_as_palindrome".} =
  if length == 0 or length > 4096: return -1
  var counts: array[26, int]
  var oddCount = 0
  var index = 0
  while index < int(length):
    let value = text[index]
    if value < 97 or value > 122: return -1
    let letter = int(value - 97)
    if counts[letter] mod 2 == 0: inc oddCount else: dec oddCount
    inc counts[letter]
    inc index
  if oddCount <= 1: 1 else: 0
