## Return the exact scaled lower bound produced by arithmetic coding.
proc arithmetic_coding*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "arithmetic_coding".} =
  if length < 2: return -1
  let count = input[0]
  if count < 1 or count > 12 or length != csize_t(count + 1): return -1

  var frequency: array[256, int64]
  var cumulative: array[257, int64]
  for index in 0 ..< int(count):
    let symbol = input[index + 1]
    if symbol < 0 or symbol > 255: return -1
    inc frequency[int(symbol)]
  for symbol in 0 ..< 256:
    cumulative[symbol + 1] = cumulative[symbol] + frequency[symbol]

  var low = 0'i64
  var high = 1'i64
  for index in 0 ..< int(count):
    let symbol = int(input[index + 1])
    let range = high - low
    let base = low * count
    high = base + range * cumulative[symbol + 1]
    low = base + range * cumulative[symbol]
  low
