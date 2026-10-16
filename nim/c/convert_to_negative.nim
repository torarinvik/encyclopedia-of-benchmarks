## Portable byte-channel negative transform.
proc convert_to_negative*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "convert_to_negative".} =
  if values == nil or length < 1 or length > csize_t(4096): return -1
  let countValue = values[0]
  if countValue < 0 or countValue > 4095 or csize_t(countValue) != length - 1: return -1
  let count = int(countValue)
  for index in 0 ..< count:
    if values[index + 1] < 0 or values[index + 1] > 255: return -1
  if csize_t(count) > outputCapacity or (count != 0 and output == nil): return -2
  for index in 0 ..< count:
    output[index] = uint8(255 - values[index + 1])
  countValue
