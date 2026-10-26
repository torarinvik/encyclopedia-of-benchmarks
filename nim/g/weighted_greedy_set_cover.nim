const MaxN = 16
const MaxM = 16
const MaxInput = 34
const MaxOutput = 136

proc put64(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[position + byte] = uint8((bits shr (8 * byte)) and 255)

proc bitCount(value: uint64): int =
  var bits = value
  while bits != 0:
    bits = bits and (bits - 1)
    inc result

proc weighted_greedy_set_cover*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "weighted_greedy_set_cover".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 1 or m64 > int64(MaxM) or
      int64(length) != 2 + 2 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  let full = (1'u64 shl n) - 1
  var weight: array[MaxM, int64]
  var masks: array[MaxM, uint64]
  var unionMask = 0'u64
  for setId in 0 ..< m:
    weight[setId] = input[2 + setId]
    let maskValue = input[2 + m + setId]
    if weight[setId] < 0 or weight[setId] > 10000 or maskValue < 0 or
        (cast[uint64](maskValue) and not full) != 0: return -1
    masks[setId] = cast[uint64](maskValue)
    unionMask = unionMask or masks[setId]
  if unionMask != full: return -1

  var covered = 0'u64
  var selected: array[MaxM, int]
  var selectedCount = 0
  while covered != full:
    var best = -1
    var bestGain = 0
    for setId in 0 ..< m:
      let gain = bitCount(masks[setId] and not covered)
      if gain == 0: continue
      if best < 0 or weight[setId] * int64(bestGain) < weight[best] * int64(gain):
        best = setId
        bestGain = gain
    if best < 0: return -1
    selected[selectedCount] = best
    inc selectedCount
    covered = covered or masks[best]

  let outputBytes = 8 * (selectedCount + 1)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var staged: array[MaxOutput, uint8]
  put64(addr staged[0], 0, int64(selectedCount))
  for index in 0 ..< selectedCount:
    put64(addr staged[0], 8 * (index + 1), int64(selected[index]))
  for index in 0 ..< outputBytes: output[index] = staged[index]
  int64(outputBytes)
