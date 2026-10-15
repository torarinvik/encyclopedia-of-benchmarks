const MaxLength = 4096
proc punctuation(value: int64): bool =
  (value >= 33 and value <= 47) or (value >= 58 and value <= 64) or
  (value >= 91 and value <= 96) or (value >= 123 and value <= 126)
proc fold(value: int64): int64 =
  if value >= 65 and value <= 90: value + 32 else: value
proc findpalindrome*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "findpalindrome".} =
  if length > csize_t(MaxLength): return -1
  for i in 0 ..< int(length):
    if input[i] < 32 or input[i] > 126: return -1
  var written = 0
  var found = false
  var segment = 0
  for ending in 0 .. int(length):
    if ending < int(length) and input[ending] != 32: continue
    var tokenLength = 0
    for i in segment ..< ending:
      if not punctuation(input[i]): inc tokenLength
    var left = segment
    var right = ending
    var matched = true
    while left < right:
      while left < right and punctuation(input[left]): inc left
      while left < right and punctuation(input[right - 1]): dec right
      if left < right:
        if fold(input[left]) != fold(input[right - 1]):
          matched = false
          break
        inc left
        dec right
    if tokenLength > 1 and matched:
      let needed = tokenLength + (if found: 1 else: 0)
      if written + needed > int(outputCapacity): return -2
      if found:
        output[written] = 0
        inc written
      for i in segment ..< ending:
        if not punctuation(input[i]):
          output[written] = uint8(input[i])
          inc written
      found = true
    segment = ending + 1
  int64(written)
