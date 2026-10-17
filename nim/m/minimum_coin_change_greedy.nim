const MinTarget = -4096'i64
const MaxTarget = 4096'i64
const MaxDenominations = 32
const MaxInputValues = 2 + MaxDenominations
const MaxOutputBytes = (1 + 4096) * 4

proc writeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u32)

proc minimum_coin_change_greedy*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "minimum_coin_change_greedy".} =
  if input == nil or length < 2 or length > MaxInputValues: return -1
  let target = input[0]
  let countValue = input[1]
  if target < MinTarget or target > MaxTarget or countValue < 0 or countValue > MaxDenominations: return -1
  let denominationCount = int(countValue)
  if int(length) != 2 + denominationCount: return -1

  var denominations: array[MaxDenominations, int32]
  var previous = 0'i64
  for index in 0 ..< denominationCount:
    let denomination = input[2 + index]
    if denomination < 1 or denomination > 4096 or denomination <= previous: return -1
    denominations[index] = int32(denomination)
    previous = denomination

  var chosen: array[4096, int32]
  var chosenCount = 0
  if target > 0:
    var remaining = target
    for index in countdown(denominationCount - 1, 0):
      let denomination = denominations[index]
      while remaining >= int64(denomination):
        remaining -= int64(denomination)
        chosen[chosenCount] = denomination
        inc chosenCount

  let needed = (1 + chosenCount) * 4
  if output == nil or capacity < csize_t(needed): return -2
  writeI32Le(output, 0, int32(chosenCount))
  for index in 0 ..< chosenCount:
    writeI32Le(output, 4 + 4 * index, chosen[index])
  int64(needed)
