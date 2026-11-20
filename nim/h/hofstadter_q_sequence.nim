const MaxIndex = 128'i64
const MaxParseableLength = 2

proc hofstadter_q_sequence*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hofstadter_q_sequence".} =
  if input == nil or length < 1 or length > csize_t(MaxParseableLength): return -1
  if length != 1 or input[0] < 1 or input[0] > MaxIndex: return -1

  let target = int(input[0])
  var q: array[MaxIndex.int + 1, int64]
  q[1] = 1
  if target >= 2: q[2] = 1
  for n in 3 .. target:
    let left = int64(n) - q[n - 1]
    let right = int64(n) - q[n - 2]
    if left < 1 or right < 1 or left >= int64(n) or right >= int64(n): return -1
    q[n] = q[int(left)] + q[int(right)]
  q[target]
