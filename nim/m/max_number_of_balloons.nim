## Count how many copies of balloon the text can supply.
proc max_number_of_balloons*(text: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "max_number_of_balloons".} =
  if length > 256: return -1
  var b = 0'i64
  var a = 0'i64
  var l = 0'i64
  var o = 0'i64
  var n = 0'i64
  for index in 0 ..< int(length):
    let value = text[index]
    if value < 97 or value > 122: return -1
    if value == 98: inc b
    elif value == 97: inc a
    elif value == 108: inc l
    elif value == 111: inc o
    elif value == 110: inc n
  l = l div 2
  o = o div 2
  result = min(b, a)
  result = min(result, l)
  result = min(result, o)
  result = min(result, n)
