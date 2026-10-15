## Decode an exact arithmetic-coded lower-bound numerator.
proc arithmetic_decoding*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "arithmetic_decoding".} =
  if input.isNil or length < 5: return -1
  let count = input[0]
  let alphabetSize = input[1]
  if count < 1 or count > 12 or alphabetSize < 1 or alphabetSize > count or length != csize_t(3 + 2 * alphabetSize): return -1

  var denominator = 1'i64
  for step in 0 ..< int(count): denominator *= count
  let code = input[2]
  if code < 0 or code >= denominator: return -1

  var symbols: array[12, int64]
  var cumulative: array[13, int64]
  var total = 0'i64
  for index in 0 ..< int(alphabetSize):
    let symbol = input[3 + 2 * index]
    let frequency = input[4 + 2 * index]
    if symbol < 0 or symbol > 255 or frequency < 1 or frequency > count or (index > 0 and symbol <= symbols[index - 1]): return -1
    symbols[index] = symbol
    total += frequency
    cumulative[index + 1] = total
  if total != count: return -1
  if capacity < csize_t(count) or output.isNil: return -2

  var low = 0'i64
  var high = 1'i64
  var scale = denominator div count
  for step in 0 ..< int(count):
    let range = high - low
    let base = low * count
    var found = false
    for index in 0 ..< int(alphabetSize):
      let symbolLow = base + range * cumulative[index]
      let symbolHigh = base + range * cumulative[index + 1]
      if code >= symbolLow * scale and code < symbolHigh * scale:
        output[step] = uint8(symbols[index])
        low = symbolLow
        high = symbolHigh
        found = true
        break
    if not found: return -1
    if step + 1 < int(count): scale = scale div count
  count
