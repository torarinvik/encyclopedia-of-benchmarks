## Check whether ASCII letters form an isogram, ignoring case and spaces.
proc isogram*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "isogram".} =
  if length > 4096 or (length > 0 and values.isNil): return -1
  var seen: array[26, bool]
  var index = 0
  while index < int(length):
    var value = values[index]
    if value == 32:
      inc index
      continue
    if value >= 65 and value <= 90: value += 32
    if value < 97 or value > 122: return -1
    let letter = int(value - 97)
    if seen[letter]: return 0
    seen[letter] = true
    inc index
  1
