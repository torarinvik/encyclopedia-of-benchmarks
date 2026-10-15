## Compare the linked-list value sequence from both ends without mutation.
proc palindrome_linked_list*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "palindrome_linked_list".} =
  if length > 100000:
    return -1
  for index in 0 ..< length:
    if values[index] < 0 or values[index] > 9:
      return -1

  var left = csize_t(0)
  var right = length
  while left < right:
    dec right
    if values[left] != values[right]:
      return 0
    inc left
  1
