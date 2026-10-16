## Apply the bounded Java EMAFilter recurrence to an integer sample stream.
proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc ema_filter*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "ema_filter".} =
  if input == nil or length < 2 or length > 7: return -1
  let alphaUnits = input[0]
  let countValue = input[1]
  if alphaUnits < 1 or alphaUnits > 1024 or countValue < 0 or countValue > 4 or int(length) != 2 + int(countValue): return -1
  let count = int(countValue)
  for index in 0 ..< count:
    if input[index + 2] < -1_000_000 or input[index + 2] > 1_000_000: return -1
  let required = count * 8
  if outputCapacity < csize_t(required) or (required > 0 and output == nil): return -2

  let alpha = float64(alphaUnits) / 1024.0
  var emaValue = 0.0
  for index in 0 ..< count:
    let sample = float64(input[index + 2])
    if index == 0: emaValue = sample
    else: emaValue = alpha * sample + (1.0 - alpha) * emaValue
    putF64Le(output, index * 8, emaValue)
  int64(required)
