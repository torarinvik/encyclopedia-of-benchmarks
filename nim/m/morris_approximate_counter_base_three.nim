const MaxUpdates = 30
const MaxValidInputValues = 1 + MaxUpdates
const MaxParseableInputValues = MaxValidInputValues + 1
const DrawSpace = 205891132094649'u64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: csize_t, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + csize_t(byte)] = uint8((bits shr (8 * byte)) and 255)

proc morris_approximate_counter_base_three*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "morris_approximate_counter_base_three".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableInputValues): return -1
  let updatesValue = input[0]
  if updatesValue < 0 or updatesValue > int64(MaxUpdates): return -1
  let updates = int(updatesValue)
  if length != csize_t(1 + updates): return -1

  var state = 0
  var threshold = DrawSpace
  var estimate = 0'u64
  for event in 0 ..< updates:
    let drawValue = input[1 + event]
    if drawValue < 0 or uint64(drawValue) >= DrawSpace: return -1
    if uint64(drawValue) < threshold:
      inc state
      threshold = threshold div 3
      estimate = 3 * estimate + 1

  if output.isNil or capacity < 16: return -2
  storeI64Le(output, 0, int64(state))
  storeI64Le(output, 8, int64(estimate))
  16
