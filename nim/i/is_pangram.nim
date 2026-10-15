## ASCII pangram predicate: ignore nonletters and ASCII letter case.
proc is_pangram*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "is_pangram".} =
  if length > 4096 or (length > 0 and values.isNil): return -1
  var seen: array[26, bool]
  var found = 0
  var index = 0
  while index < int(length):
    var value = values[index]
    if value < 0 or value > 127: return -1
    if value >= 65 and value <= 90: value += 32
    if value >= 97 and value <= 122:
      let letter = int(value - 97)
      if not seen[letter]:
        seen[letter] = true
        inc found
    inc index
  if found == 26: 1 else: 0
