## Find the rightmost longest ASCII alphanumeric palindrome with substring DP.
const MaxLength = 1000

proc isAsciiAlphanumeric(value: int64): bool =
  (value >= ord('0').int64 and value <= ord('9').int64) or
  (value >= ord('A').int64 and value <= ord('Z').int64) or
  (value >= ord('a').int64 and value <= ord('z').int64)

proc longest_palindromic_substring_dp*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "longest_palindromic_substring_dp".} =
  if values == nil or length == 0 or length > MaxLength: return -1
  for index in 0'u64 ..< uint64(length):
    if not isAsciiAlphanumeric(values[csize_t(index)]): return -1

  let inputLength = int(length)
  var palindrome = newSeq[bool](inputLength * inputLength)
  var bestStart = 0
  var bestEnd = 0
  for gap in 0 ..< int(length):
    for startIndex in 0 ..< (inputLength - gap):
      let endIndex = startIndex + gap
      var isPalindrome = false
      if gap == 0:
        isPalindrome = true
      elif gap == 1:
        isPalindrome = values[startIndex] == values[endIndex]
      else:
        isPalindrome = values[startIndex] == values[endIndex] and
          palindrome[(startIndex + 1) * inputLength + endIndex - 1]
      palindrome[startIndex * inputLength + endIndex] = isPalindrome
      if isPalindrome:
        bestStart = startIndex
        bestEnd = endIndex

  let bestLength = bestEnd - bestStart + 1
  if output == nil or outputCapacity < csize_t(bestLength): return -2
  for index in 0 ..< bestLength:
    output[index] = uint8(values[bestStart + index])
  int64(bestLength)
