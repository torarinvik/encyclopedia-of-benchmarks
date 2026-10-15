## Count chunks by peeling the shortest matching prefix and suffix.
proc longest_chunked_palindrome_decomposition*(text: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "longest_chunked_palindrome_decomposition".} =
  if length > 128: return -1
  for index in 0 ..< int(length):
    if text[index] < 1 or text[index] > 127: return -1
  var left = 0
  var right = int(length)
  var chunks = 0'i64
  while left < right:
    let remaining = right - left
    var size = 1
    var matched = false
    while size <= remaining div 2 and not matched:
      var equal = true
      for offset in 0 ..< size:
        if text[left + offset] != text[right - size + offset]:
          equal = false
          break
      if equal:
        chunks += 2
        left += size
        right -= size
        matched = true
      else:
        inc size
    if not matched: return chunks + 1
  chunks
