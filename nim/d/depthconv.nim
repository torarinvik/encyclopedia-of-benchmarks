const MaxChannels = 8
proc roundedShift(value: int64, shift: int): int64 =
  let divisor = 1'i64 shl shift
  if value >= 0: return value div divisor
  -((-value + divisor - 1) div divisor)
proc depthconv*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "depthconv".} =
  if values.isNil or length < 1 or length > csize_t(1 + 11 * MaxChannels): return -1
  let channelsValue = values[0]
  if channelsValue < 1 or channelsValue > MaxChannels or length != csize_t(1 + 11 * channelsValue): return -1
  let channels = int(channelsValue)
  for i in 1 ..< 1 + 8 * channels:
    if values[i] < -128 or values[i] > 127: return -1
  for i in 1 + 8 * channels ..< 1 + 9 * channels:
    if values[i] < -1_000_000 or values[i] > 1_000_000: return -1
  for i in 1 + 9 * channels ..< 1 + 10 * channels:
    if values[i] < 0 or values[i] > 2_147_483_647: return -1
  for i in 1 + 10 * channels ..< int(length):
    if values[i] < -8 or values[i] > 0: return -1
  if output.isNil or capacity < csize_t(channels): return -2
  for ch in 0 ..< channels:
    var acc: int32 = 0
    for row in 0 ..< 4:
      acc += int32(values[1 + row * channels + ch] + 128) * int32(values[1 + 4 * channels + row * channels + ch])
    acc += int32(values[1 + 8 * channels + ch])
    let shift = int(31 - values[1 + 10 * channels + ch])
    let round = 1'i64 shl (shift - 1)
    var scaled = roundedShift(int64(acc) * values[1 + 9 * channels + ch] + round, shift)
    scaled = max(-128'i64, min(127'i64, scaled))
    output[ch] = uint8(int8(scaled))
  channels.int64
