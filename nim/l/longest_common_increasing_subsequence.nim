const MaxInputLength = 67

proc longest_common_increasing_subsequence*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "longest_common_increasing_subsequence".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let n = input[0]
  let m = input[1]
  if n < 0 or n > 32 or m < 0 or m > 32: return -1
  if length != csize_t(2 + n + m): return -1
  for index in 0 ..< int(n + m):
    if input[2 + index] < -16 or input[2 + index] > 16: return -1

  var endingAt: array[32, int64]
  for i in 0 ..< int(n):
    let value = input[2 + i]
    var bestSmaller = 0'i64
    for j in 0 ..< int(m):
      let other = input[2 + int(n) + j]
      if value > other:
        if endingAt[j] > bestSmaller: bestSmaller = endingAt[j]
      elif value == other and bestSmaller + 1 > endingAt[j]:
        endingAt[j] = bestSmaller + 1
  var answer = 0'i64
  for j in 0 ..< int(m):
    if endingAt[j] > answer: answer = endingAt[j]
  answer
