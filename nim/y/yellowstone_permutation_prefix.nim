const
  MaxN = 64'i64
  MinCap = 3'i64
  MaxCap = 256'i64
  MaxParseableLength = 3

proc yppGcd(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc yellowstone_permutation_prefix*(input: ptr UncheckedArray[int64],
                                     length: csize_t): int64
    {.cdecl, exportc: "yellowstone_permutation_prefix".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  if length != 2: return -1
  let requested = input[0]
  let candidateCap = input[1]
  if requested < 1 or requested > MaxN or candidateCap < MinCap or candidateCap > MaxCap: return -1

  var terms: array[64, int64]
  var used: array[257, bool]
  terms[0] = 1
  terms[1] = 2
  terms[2] = 3
  if requested <= 3: return terms[int(requested) - 1]
  used[1] = true
  used[2] = true
  used[3] = true

  var termCount = 3
  while termCount < int(requested):
    let twoBack = terms[termCount - 2]
    let previous = terms[termCount - 1]
    var candidate = 1'i64
    while candidate <= candidateCap:
      if not used[int(candidate)] and yppGcd(candidate, twoBack) > 1 and yppGcd(candidate, previous) == 1:
        break
      inc candidate
    if candidate > candidateCap: return -1
    terms[termCount] = candidate
    used[int(candidate)] = true
    inc termCount
  terms[int(requested) - 1]
