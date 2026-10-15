proc excel_title_to_column*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "excel_title_to_column".} =
  if values == nil or length < 2 or length > 13: return -1
  let count = values[0]
  if count < 1 or count > 12 or length != csize_t(1 + count): return -1

  var column = 0'i64
  for index in 0 ..< int(count):
    var letter = values[1 + index]
    if letter >= 97 and letter <= 122: letter -= 32
    if letter < 65 or letter > 90: return -1
    column = column * 26 + letter - 65 + 1
  column
