const MaxCallCount = 1_000_000'i64
const Modulus = 139_968'i64
const FractionScale = 1_000_000_000'i64
const MaxOutputBytes = 13

proc shootout_random*(callCount: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "shootout_random".} =
  if callCount < 1 or callCount > MaxCallCount: return -1

  var state = 42'i64
  for _ in 0 ..< int(callCount):
    state = (state * 3877'i64 + 29573'i64) mod Modulus

  let scaled = (100'i64 * state * FractionScale + Modulus div 2) div Modulus
  var whole = scaled div FractionScale
  var fraction = scaled mod FractionScale
  var staged: array[MaxOutputBytes, uint8]
  var reversedDigits: array[3, uint8]
  var digitCount = 0
  while true:
    reversedDigits[digitCount] = uint8(48'i64 + whole mod 10)
    inc digitCount
    whole = whole div 10
    if whole == 0: break

  var used = 0
  while digitCount > 0:
    dec digitCount
    staged[used] = reversedDigits[digitCount]
    inc used
  staged[used] = uint8(ord('.'))
  inc used
  var place = 100_000_000'i64
  while place > 0:
    staged[used] = uint8(48'i64 + fraction div place)
    inc used
    fraction = fraction mod place
    place = place div 10
  staged[used] = 10'u8
  inc used

  if output.isNil or outputCapacity < csize_t(used): return -2
  for index in 0 ..< used: output[index] = staged[index]
  int64(used)
