## Enumerate amicable pairs below an exclusive upper limit using a divisor-sum sieve.
const MaxLimit = 8_000

proc writeU32Le(output: ptr UncheckedArray[uint8], position: var int,
    value: int64) =
  var encoded = uint32(value)
  for _ in 0 ..< 4:
    output[position] = uint8(encoded and 0xff'u32)
    encoded = encoded shr 8
    inc position

proc amicablePairsBelow*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "amicable_pairs_below".} =
  if values == nil or length != 1: return -1
  if values[0] < 1 or values[0] > MaxLimit: return -1
  let limit = int(values[0])
  var divisorSums: array[0 .. MaxLimit - 1, int64]
  for index in 0 ..< MaxLimit: divisorSums[index] = 0
  for divisor in 1 ..< limit:
    var multiple = divisor * 2
    while multiple < limit:
      divisorSums[multiple] += int64(divisor)
      multiple += divisor

  var pairCount = 0
  for smaller in 2 ..< limit:
    let larger = divisorSums[smaller]
    if larger > int64(smaller) and larger < int64(limit) and
        divisorSums[int(larger)] == int64(smaller):
      inc pairCount
  let required = csize_t(pairCount * 8)
  if outputCapacity < required or (required > 0 and output == nil): return -2

  var position = 0
  for smaller in 2 ..< limit:
    let larger = divisorSums[smaller]
    if larger > int64(smaller) and larger < int64(limit) and
        divisorSums[int(larger)] == int64(smaller):
      writeU32Le(output, position, int64(smaller))
      writeU32Le(output, position, larger)
  int64(pairCount)
