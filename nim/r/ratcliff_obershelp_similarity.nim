const MaxText = 32
const MaxInputLength = 67

proc longestMatch(input: ptr UncheckedArray[int64], firstBase, secondBase: int,
                  a0, a1, b0, b1: int): int64 =
  var dp: array[33, int64]
  let width = b1 - b0
  var bestLength = 0
  var bestA = 0
  var bestB = 0
  for i in a0 ..< a1:
    var diagonal = 0'i64
    for column in 1 .. width:
      let old = dp[column]
      let j = b0 + column - 1
      if input[firstBase + i] == input[secondBase + j]:
        let current = int(diagonal) + 1
        dp[column] = int64(current)
        if current > bestLength:
          bestLength = current
          bestA = i + 1 - current
          bestB = j + 1 - current
      else:
        dp[column] = 0
      diagonal = old
  int64(bestLength * 4096 + bestA * 64 + bestB)

proc matchedCharacters(input: ptr UncheckedArray[int64], firstBase,
                       secondBase, a0, a1, b0, b1: int): int64 =
  if a0 >= a1 or b0 >= b1: return 0
  let packed = int(longestMatch(input, firstBase, secondBase, a0, a1, b0, b1))
  let block = packed div 4096
  if block == 0: return 0
  let rest = packed mod 4096
  let a = rest div 64
  let b = rest mod 64
  int64(block) + matchedCharacters(input, firstBase, secondBase, a0, a, b0, b)
    + matchedCharacters(input, firstBase, secondBase, a + block, a1,
                        b + block, b1)

proc ratcliff_obershelp_similarity*(input: ptr UncheckedArray[int64],
                                    length: csize_t): int64
    {.cdecl, exportc: "ratcliff_obershelp_similarity".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > int64(MaxText) or input[1] < 0 or input[1] > int64(MaxText): return -1
  let firstLength = int(input[0])
  let secondLength = int(input[1])
  if int(length) != 2 + firstLength + secondLength: return -1
  for i in 0 ..< firstLength + secondLength:
    if input[2 + i] < 1 or input[2 + i] > 127: return -1
  if firstLength == 0 or secondLength == 0: return 0
  let common = matchedCharacters(input, 2, 2 + firstLength,
                                 0, firstLength, 0, secondLength)
  (200 * common) div int64(firstLength + secondLength)
