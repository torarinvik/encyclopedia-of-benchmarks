proc fifteen_puzzle_solvability*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "fifteen_puzzle_solvability".} =
  if input.isNil or length != csize_t(16): return -1

  var blank = -1'i64
  for i in 0 ..< 16:
    let value = input[i]
    if value < 0 or value >= 16: return -1
    for j in 0 ..< i:
      if value == input[j]: return -1
    if value == 0: blank = i.int64
  if blank < 0: return -1

  var inversions = 0'i64
  for i in 0 ..< 16:
    if input[i] == 0: continue
    for j in i + 1 ..< 16:
      if input[j] != 0 and input[i] > input[j]: inc inversions
  let blankRowFromTop = blank div 4 + 1
  if (inversions + blankRowFromTop) mod 2 == 0: return 1
  0
