const MaxValues = 256
const MaxPairs = MaxValues div 2

proc sortPairs(low, high, scratchLow, scratchHigh: ptr UncheckedArray[int64], count: int) =
  var width = 1
  while width < count:
    var start = 0
    while start < count:
      let middle = min(start + width, count)
      let endIndex = min(middle + width, count)
      var left = start
      var right = middle
      var output = start
      while left < middle and right < endIndex:
        let source = if low[left] <= low[right]: left else: right
        scratchLow[output] = low[source]
        scratchHigh[output] = high[source]
        if source == left: inc left else: inc right
        inc output
      while left < middle:
        scratchLow[output] = low[left]
        scratchHigh[output] = high[left]
        inc left; inc output
      while right < endIndex:
        scratchLow[output] = low[right]
        scratchHigh[output] = high[right]
        inc right; inc output
      for index in start ..< endIndex:
        low[index] = scratchLow[index]
        high[index] = scratchHigh[index]
      start += width * 2
    if width > count div 2: break
    width *= 2

proc binaryInsert(values: ptr UncheckedArray[int64], length: var int, item: int64) =
  var low = 0
  var high = length
  while low < high:
    let middle = low + (high - low) div 2
    if values[middle] < item: low = middle + 1 else: high = middle
  for index in countdown(length, low + 1):
    values[index] = values[index - 1]
  values[low] = item
  inc length

proc merge_insertion_sort*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "merge_insertion_sort".} =
  if length > csize_t(MaxValues): return
  let n = int(length)
  var pairLow, pairHigh, scratchLow, scratchHigh: array[MaxPairs, int64]
  var chain: array[MaxValues, int64]
  let pairCount = n div 2
  for pair in 0 ..< pairCount:
    let first = values[pair * 2]
    let second = values[pair * 2 + 1]
    if first <= second:
      pairLow[pair] = first; pairHigh[pair] = second
    else:
      pairLow[pair] = second; pairHigh[pair] = first
  sortPairs(cast[ptr UncheckedArray[int64]](addr pairLow[0]),
    cast[ptr UncheckedArray[int64]](addr pairHigh[0]),
    cast[ptr UncheckedArray[int64]](addr scratchLow[0]),
    cast[ptr UncheckedArray[int64]](addr scratchHigh[0]), pairCount)
  var chainLength = 0
  for pair in 0 ..< pairCount:
    chain[chainLength] = pairLow[pair]
    inc chainLength
  if pairCount > 0:
    chain[chainLength] = pairHigh[pairCount - 1]
    inc chainLength
  if n mod 2 != 0: binaryInsert(cast[ptr UncheckedArray[int64]](addr chain[0]), chainLength, values[n - 1])
  for pair in 0 ..< max(0, pairCount - 1):
    binaryInsert(cast[ptr UncheckedArray[int64]](addr chain[0]), chainLength, pairHigh[pair])
  for index in 0 ..< n: values[index] = chain[index]
