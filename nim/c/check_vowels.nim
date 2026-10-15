const MaxLength = 4096

## Return whether any lowercase ASCII vowel appears in the input.
proc check_vowels*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "check_vowels".} =
  if length > MaxLength or (length > 0 and values == nil): return -1
  for i in 0 ..< int(length):
    if values[i] < 97 or values[i] > 122: return -1
  for i in 0 ..< int(length):
    let value = values[i]
    if value in [97'i64, 101, 105, 111, 117]: return 1
  0
