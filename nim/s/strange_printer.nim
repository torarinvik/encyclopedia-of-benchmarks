const MaxLength = 8
const MaxParseableLength = MaxLength + 2
const TableSide = MaxLength + 1

proc strange_printer*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "strange_printer".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseableLength): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxLength or length != csize_t(nValue + 1): return -1
  let n = int(nValue)
  for position in 0..<n:
    if input[position + 1] < 0 or input[position + 1] > 2: return -1
  if n == 0: return 0

  var dp: array[TableSide * TableSide, int64]
  for left in countdown(n - 1, 0):
    dp[left * TableSide + left] = 1
    for right in left + 1..<n:
      var best = dp[(left + 1) * TableSide + right] + 1
      for merge in left + 1..right:
        if input[left + 1] != input[merge + 1]: continue
        let middle = if merge == left + 1: 0'i64 else: dp[(left + 1) * TableSide + merge - 1]
        best = min(best, middle + dp[merge * TableSide + right])
      dp[left * TableSide + right] = best
  dp[n - 1]
