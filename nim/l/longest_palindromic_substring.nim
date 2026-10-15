## Find the leftmost longest ASCII alphanumeric palindrome by expanding centers.
proc isAsciiAlphanumeric(value: int64): bool =
  (value >= ord('0').int64 and value <= ord('9').int64) or
  (value >= ord('A').int64 and value <= ord('Z').int64) or
  (value >= ord('a').int64 and value <= ord('z').int64)

proc longest_palindromic_substring*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "longest_palindromic_substring".} =
  if length == 0 or length > 1000 or values == nil: return -1
  for index in 0'u64 ..< uint64(length):
    if not isAsciiAlphanumeric(values[csize_t(index)]): return -1

  var bestStart = csize_t(0)
  var bestLength = csize_t(1)
  for center in 0'u64 ..< uint64(length):
    var left = csize_t(center)
    var right = csize_t(center)
    while left > 0 and right + 1 < length and
        values[left - 1] == values[right + 1]:
      dec left
      inc right
    var candidateLength = right - left + 1
    if candidateLength > bestLength:
      bestStart = left
      bestLength = candidateLength

    left = csize_t(center)
    right = csize_t(center) + 1
    while right < length and values[left] == values[right]:
      candidateLength = right - left + 1
      if candidateLength > bestLength:
        bestStart = left
        bestLength = candidateLength
      if left == 0 or right + 1 == length: break
      dec left
      inc right

  if outputCapacity < bestLength or output == nil: return -2
  for index in 0'u64 ..< uint64(bestLength):
    output[index] = uint8(values[bestStart + csize_t(index)])
  int64(bestLength)
