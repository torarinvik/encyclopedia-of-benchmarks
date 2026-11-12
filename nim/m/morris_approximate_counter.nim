const MaxUpdates = 53
const DrawBits = 53
const MaxInputValues = 1 + MaxUpdates
const DrawLimit = 1'u64 shl DrawBits

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: csize_t, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + csize_t(byte)] = uint8((bits shr (8 * byte)) and 255)

proc morris_approximate_counter*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "morris_approximate_counter".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputValues): return -1
  let updatesValue = input[0]
  if updatesValue < 1 or updatesValue > int64(MaxUpdates): return -1
  let updates = int(updatesValue)
  if length != csize_t(1 + updates): return -1

  var state = 0
  for event in 0 ..< updates:
    let drawValue = input[1 + event]
    if drawValue < 0 or uint64(drawValue) >= DrawLimit: return -1
    let threshold = 1'u64 shl (DrawBits - state)
    if uint64(drawValue) < threshold: inc state

  if output.isNil or capacity < 16: return -2
  let estimate = int64((1'u64 shl state) - 1)
  storeI64Le(output, 0, int64(state))
  storeI64Le(output, 8, estimate)
  16
