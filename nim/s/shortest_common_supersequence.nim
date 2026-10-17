proc shortest_common_supersequence*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "shortest_common_supersequence".} =
  if input == nil or length < 2 or length > 130: return -1
  let mValue = input[0]
  let nValue = input[1]
  if mValue < 0 or mValue > 64 or nValue < 0 or nValue > 64: return -1
  let m = int(mValue)
  let n = int(nValue)
  if length != csize_t(2 + m + n): return -1
  for index in 0 ..< m + n:
    if input[2 + index] < 32 or input[2 + index] > 126: return -1

  var lcs: array[65, array[65, int64]]
  var i = 1
  while i <= m:
    var j = 1
    while j <= n:
      if input[1 + i] == input[1 + m + j]:
        lcs[i][j] = lcs[i - 1][j - 1] + 1
      else:
        lcs[i][j] = max(lcs[i - 1][j], lcs[i][j - 1])
      inc j
    inc i

  var reversed: array[128, uint8]
  var used = 0
  i = m
  var j = n
  while i > 0 and j > 0:
    if input[1 + i] == input[1 + m + j]:
      reversed[used] = uint8(input[1 + i])
      inc used
      dec i
      dec j
    elif lcs[i - 1][j] > lcs[i][j - 1]:
      reversed[used] = uint8(input[1 + i])
      inc used
      dec i
    else:
      # The pinned implementations choose Y when the LCS values tie.
      reversed[used] = uint8(input[1 + m + j])
      inc used
      dec j
  while i > 0:
    reversed[used] = uint8(input[1 + i])
    inc used
    dec i
  while j > 0:
    reversed[used] = uint8(input[1 + m + j])
    inc used
    dec j

  if output == nil or capacity < csize_t(used): return -2
  for index in 0 ..< used:
    output[index] = reversed[used - 1 - index]
  int64(used)
