proc pfrLocalForwardDecision*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"pfr_local_forward_decision".} =
  if input.isNil or length != csize_t(2): return -1
  let angle = input[0]
  let draw = input[1]
  if angle < 0 or angle > 180000000 or draw < 0 or draw >= 1000000: return -1
  var forward = 0'i64
  if angle >= 134000000 or 180 * draw < angle: forward = 1
  if output.isNil or capacity < csize_t(8): return -2
  let bits = cast[uint64](forward)
  for byte in 0..<8:
    output[byte] = uint8((bits shr (8 * byte)) and 255)
  8
