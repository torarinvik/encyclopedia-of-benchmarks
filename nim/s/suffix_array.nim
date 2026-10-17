const MaxTextLength = 64
const MaxInputLength = 65

proc pairLess(left, right: int, rank: array[MaxTextLength, int64],
    length, step: int): bool =
  if rank[left] != rank[right]: return rank[left] < rank[right]
  let leftSecond = if left + step < length: rank[left + step] else: -1'i64
  let rightSecond = if right + step < length: rank[right + step] else: -1'i64
  leftSecond < rightSecond

proc suffix_array*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "suffix_array".} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let countValue = values[0]
  if countValue < 0 or countValue > int64(MaxTextLength): return -1
  let count = int(countValue)
  if length != csize_t(1 + count): return -1
  for i in 0 ..< count:
    if values[1 + i] < 0 or values[1 + i] > 127: return -1

  let outputBytes = count * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  if count == 0: return 0

  var suffixes: array[MaxTextLength, int]
  var rank: array[MaxTextLength, int64]
  var nextRank: array[MaxTextLength, int64]
  for i in 0 ..< count:
    suffixes[i] = i
    rank[i] = values[1 + i]

  var step = 1
  while step < count:
    for i in 1 ..< count:
      let key = suffixes[i]
      var position = i
      while position > 0 and pairLess(key, suffixes[position - 1], rank, count, step):
        suffixes[position] = suffixes[position - 1]
        dec position
      suffixes[position] = key
    nextRank[suffixes[0]] = 0
    for i in 1 ..< count:
      let previous = suffixes[i - 1]
      let current = suffixes[i]
      let previousSecond = if previous + step < count: rank[previous + step] else: -1'i64
      let currentSecond = if current + step < count: rank[current + step] else: -1'i64
      nextRank[current] = nextRank[previous]
      if rank[previous] != rank[current] or previousSecond != currentSecond:
        inc nextRank[current]
    for i in 0 ..< count: rank[i] = nextRank[i]
    if rank[suffixes[count - 1]] == int64(count - 1): break
    step *= 2

  for i in 0 ..< count:
    let bits = uint64(suffixes[i])
    for byte in 0 ..< 8:
      output[i * 8 + byte] = uint8((bits shr (byte * 8)) and 255)
  int64(outputBytes)
