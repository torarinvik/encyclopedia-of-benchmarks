## ASCII alphanumeric palindrome check, ignoring case and punctuation.
proc isAsciiAlphanumeric(value: int64): bool =
  (value >= 48 and value <= 57) or (value >= 65 and value <= 90) or
    (value >= 97 and value <= 122)

proc asciiLower(value: int64): int64 =
  if value >= 65 and value <= 90: value + 32 else: value

proc valid_palindrome*(text: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "valid_palindrome".} =
  if length > 4096:
    return -1
  var index = csize_t(0)
  while index < length:
    if text[index] < 0'i64 or text[index] > 127'i64:
      return -1
    inc index
  var left = csize_t(0)
  var right = length
  while left < right:
    while left < right and not isAsciiAlphanumeric(text[left]):
      inc left
    while left < right and not isAsciiAlphanumeric(text[right - 1]):
      dec right
    if left < right and asciiLower(text[left]) != asciiLower(text[right - 1]):
      return 0
    if left < right:
      inc left
      dec right
  1
