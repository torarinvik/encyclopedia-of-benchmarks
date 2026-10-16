const MaxN = 256
const MaxOutput = 527

proc writeI64(output: var array[MaxOutput, uint8], position: int, value: int64): int =
  let bits = cast[uint64](value)
  for i in 0 ..< 8: output[position + i] = uint8((bits shr (8 * i)) and 255'u64)
  position + 8

proc min_palindromic_insert*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "min_palindromic_insert".} =
  if input.isNil or length < 1 or length > csize_t(MaxN + 1): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > int64(MaxN) or length != csize_t(nValue + 1): return -1
  let n = int(nValue)
  var chars: array[MaxN, uint8]
  for i in 0 ..< n:
    if input[i + 1] < 32 or input[i + 1] > 126: return -1
    chars[i] = uint8(input[i + 1])
  var dp: array[MaxN, array[MaxN, uint16]]
  for span in 2 .. n:
    for left in 0 .. n - span:
      let right = left + span - 1
      if chars[left] == chars[right]:
        if span > 2: dp[left][right] = dp[left + 1][right - 1]
      else:
        dp[left][right] = min(dp[left + 1][right], dp[left][right - 1]) + 1
  let insertions = int(dp[0][n - 1])
  let palindromeLength = n + insertions
  var palindrome: array[2 * MaxN - 1, uint8]
  var left = 0
  var right = n - 1
  var outLeft = 0
  var outRight = palindromeLength - 1
  while left <= right:
    if chars[left] == chars[right]:
      palindrome[outLeft] = chars[left]
      palindrome[outRight] = chars[right]
      inc left
      if right == 0: break
      dec right
    elif dp[left + 1][right] < dp[left][right - 1]:
      palindrome[outLeft] = chars[left]
      palindrome[outRight] = chars[left]
      inc left
    else:
      palindrome[outLeft] = chars[right]
      palindrome[outRight] = chars[right]
      if right == 0: break
      dec right
    inc outLeft
    if outRight == 0: break
    dec outRight
  var payload: array[MaxOutput, uint8]
  var written = writeI64(payload, 0, int64(insertions))
  written = writeI64(payload, written, int64(palindromeLength))
  for i in 0 ..< palindromeLength: payload[written + i] = palindrome[i]
  written += palindromeLength
  if output.isNil or outputCapacity < csize_t(written): return -2
  copyMem(output, addr payload[0], written)
  int64(written)
