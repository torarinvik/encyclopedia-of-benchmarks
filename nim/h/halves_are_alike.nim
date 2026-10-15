## Compare the vowel counts in two equal ASCII-letter halves.
proc halves_are_alike*(letters: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "halves_are_alike".} =
  if length > 256 or length mod 2 != 0 or (length > 0 and letters.isNil): return -1
  let half = int(length div 2)
  var first = 0
  var second = 0
  for index in 0 ..< int(length):
    let value = letters[index]
    if not ((value >= 97 and value <= 122) or (value >= 65 and value <= 90)): return -1
    if value == 97 or value == 101 or value == 105 or value == 111 or value == 117 or
        value == 65 or value == 69 or value == 73 or value == 79 or value == 85:
      if index < half: inc first
      else: inc second
  if first == second: 1 else: 0
