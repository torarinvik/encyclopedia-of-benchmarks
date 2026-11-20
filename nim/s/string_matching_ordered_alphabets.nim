const MaxText = 4096
const MaxPattern = 128
const MaxInput = 4227

proc advanceMaximalSuffix(input: ptr UncheckedArray[int64], base, segmentLength: int,
                          left, right, offset, period: var int) =
  while right + offset < segmentLength:
    let a = input[base + left + offset]
    let b = input[base + right + offset]
    if a == b:
      if offset == period:
        right += period
        offset = 1
      else:
        inc offset
    elif a > b:
      right += offset
      offset = 1
      period = right - left
    else:
      left = right
      inc right
      offset = 1
      period = 1

proc prefixRepeats(input: ptr UncheckedArray[int64], base, shift, lastIndex: int): bool =
  for q in 0 .. lastIndex:
    if input[base + q] != input[base + shift + q]: return false
  true

proc string_matching_ordered_alphabets*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "string_matching_ordered_alphabets".} =
  if input.isNil or length < 2 or length > MaxInput: return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 0 or n64 > MaxText or m64 < 1 or m64 > MaxPattern: return -1
  let n = int(n64)
  let m = int(m64)
  if length != csize_t(2 + n + m): return -1
  let patternStart = 2 + n
  for q in 0 ..< n:
    if input[2 + q] < 0 or input[2 + q] > 3: return -1
  for q in 0 ..< m:
    if input[patternStart + q] < 0 or input[patternStart + q] > 3: return -1
  if n < m: return 0

  var alignment = 0
  var matched = 0
  var suffixLeft = -1
  var suffixRight = 0
  var suffixOffset = 1
  var period = 1
  var count = 0'i64
  var offsetSum = 0'i64
  var offsetXor = 0'i64
  while alignment <= n - m:
    while alignment + matched < n and matched < m and
        input[patternStart + matched] == input[2 + alignment + matched]:
      inc matched
    if matched == 0:
      inc alignment
      suffixLeft = -1; suffixRight = 0; suffixOffset = 1; period = 1
      continue
    if matched == m:
      inc count
      offsetSum += int64(alignment)
      offsetXor = offsetXor xor int64(alignment)
      if alignment == n - m: break

    let base = 2 + alignment
    advanceMaximalSuffix(input, base, matched + 1,
                         suffixLeft, suffixRight, suffixOffset, period)
    let reusable = suffixLeft < 0 or
      (suffixLeft < period and prefixRepeats(input, base, period, suffixLeft))
    if reusable:
      alignment += period
      matched -= period
      if matched < 0: matched = 0
      if suffixRight - suffixLeft > period: suffixRight -= period
      else: suffixLeft = -1; suffixRight = 0; suffixOffset = 1; period = 1
    else:
      let conservative = min(matched - suffixLeft - 1, suffixRight + 1)
      let certified = max(suffixLeft + 1, conservative)
      alignment += certified + 1
      matched = 0
      suffixLeft = -1; suffixRight = 0; suffixOffset = 1; period = 1
  (count shl 36) or (offsetSum shl 12) or offsetXor
