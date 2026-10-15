const MaxSymbols = 26
const MaxTotalFrequency = 2_147_483_647'i64

type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc storeI64Le(output: U8Output, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[byte] = uint8(bits and 255)
    bits = bits shr 8

proc huffman_weighted_cost*(values: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "huffman_weighted_cost".} =
  if values == nil or length < 1 or length > 53: return -1
  let rawCount = values[0]
  if rawCount < 2 or rawCount > MaxSymbols or length != csize_t(1 + 2 * rawCount): return -1
  let count = int(rawCount)

  var seen: array[MaxSymbols, bool]
  var active: array[MaxSymbols, bool]
  var weights: array[MaxSymbols, int64]
  var total = 0'i64
  for index in 0 ..< count:
    let symbol = values[1 + 2 * index]
    let frequency = values[2 + 2 * index]
    if symbol < 97 or symbol > 122 or frequency < 1 or frequency > MaxTotalFrequency: return -1
    let letter = int(symbol - 97)
    if seen[letter] or total > MaxTotalFrequency - frequency: return -1
    seen[letter] = true
    active[index] = true
    weights[index] = frequency
    total += frequency

  var remaining = count
  var cost = 0'i64
  while remaining > 1:
    var first = -1
    var second = -1
    for index in 0 ..< count:
      if not active[index]: continue
      if first < 0 or weights[index] < weights[first]:
        second = first
        first = index
      elif second < 0 or weights[index] < weights[second]:
        second = index
    weights[first] += weights[second]
    active[second] = false
    cost += weights[first]
    dec remaining

  if output == nil or outputCapacity < 8: return -2
  storeI64Le(output, cost)
  cost
