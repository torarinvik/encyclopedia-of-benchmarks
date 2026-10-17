const MaxN = 12_344
const MaxParseableInputLength = MaxN + 4

proc sparse_table*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "sparse_table".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseableInputLength): return -1
  if input[0] < 1'i64 or input[0] > int64(MaxN): return -1
  let n = int(input[0])
  if length != csize_t(n + 3): return -1
  let leftValue = input[n + 1]
  let rightValue = input[n + 2]
  if leftValue < 0 or rightValue < leftValue or rightValue >= int64(n): return -1
  let left = int(leftValue)
  let right = int(rightValue)

  var levels = 1
  var span = 2
  while span <= n:
    inc levels
    span *= 2
  var table = newSeq[int64](levels * n)
  var logs = newSeq[int64](n + 1)
  logs[0] = -1
  for i in 0 ..< n:
    table[i] = int64(i)
    logs[i + 1] = logs[i] + (if (i and (i + 1)) == 0: 1'i64 else: 0'i64)

  span = 2
  for level in 1 ..< levels:
    let half = span div 2
    for i in 0 .. n - span:
      let x = int(table[(level - 1) * n + i])
      let y = int(table[(level - 1) * n + i + half])
      table[level * n + i] = int64(if input[1 + x] <= input[1 + y]: x else: y)
    span *= 2

  let queryLength = right - left + 1
  let level = int(logs[queryLength])
  let block = 1 shl level
  let x = int(table[level * n + left])
  let y = int(table[level * n + right - block + 1])
  int64(if input[1 + x] <= input[1 + y]: x else: y)
