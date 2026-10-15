const MaxLength = 1024

proc lowerAscii(value: int64): int64 =
  if value >= 65 and value <= 90: value + 32 else: value

proc check_palindrome2*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "check_palindrome2".} =
  if length > csize_t(MaxLength) or (length != 0 and values == nil): return -1
  for index in 0 ..< int(length):
    if values[index] < 32 or values[index] > 126: return -1
  var start = 0
  var ending = int(length)
  while start < ending and values[start] == 32: inc start
  while ending > start and values[ending - 1] == 32: dec ending
  let normalizedLength = ending - start
  if normalizedLength == 0 or (normalizedLength == 1 and values[start] == 48): return -1

  var palindrome = true
  for left in 0 ..< normalizedLength div 2:
    let right = normalizedLength - left - 1
    if lowerAscii(values[start + left]) != lowerAscii(values[start + right]): palindrome = false
  let suffix = if palindrome: " - a palindrome string.\n" else: " - not a palindrome string.\n"
  let required = normalizedLength + suffix.len
  if output == nil or outputCapacity < csize_t(required): return -2
  for index in 0 ..< normalizedLength:
    output[index] = uint8(lowerAscii(values[start + index]))
  for index in 0 ..< suffix.len:
    output[normalizedLength + index] = uint8(ord(suffix[index]))
  int64(required)
