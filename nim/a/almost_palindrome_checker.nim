const MaxLength = 100000

type Text = ptr UncheckedArray[int64]

proc isPalindromeRange(text: Text, leftStart, rightStart: csize_t): bool =
  var left = leftStart
  var right = rightStart
  while left < right:
    if text[left] != text[right - 1]: return false
    inc left
    dec right
  true

proc almost_palindrome_checker*(text: Text, length: csize_t): int64
    {.cdecl, exportc: "almost_palindrome_checker".} =
  if length > MaxLength: return -1
  var index = csize_t(0)
  while index < length:
    if text[index] < 97'i64 or text[index] > 122'i64: return -1
    inc index
  var left = csize_t(0)
  var right = length
  while left < right:
    if text[left] != text[right - 1]:
      if isPalindromeRange(text, left + 1, right) or isPalindromeRange(text, left, right - 1):
        return 1
      return 0
    inc left
    dec right
  1
