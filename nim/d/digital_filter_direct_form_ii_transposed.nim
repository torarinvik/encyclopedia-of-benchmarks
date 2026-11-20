type I64Input = ptr UncheckedArray[int64]
type ByteOutput = ptr UncheckedArray[uint8]

const MaxSamples = 32
const MaxOrder = 4
const MaxInputWords = 45

proc digital_filter_direct_form_ii_transposed*(input: I64Input, length: csize_t,
    output: ByteOutput, capacity: csize_t): int64 {.cdecl, exportc: "digital_filter_direct_form_ii_transposed".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputWords): return -1
  let countWord = input[0]
  let orderWord = input[1]
  if countWord < 0 or countWord > int64(MaxSamples) or orderWord < 0 or orderWord > int64(MaxOrder): return -1
  let count = int(countWord)
  let order = int(orderWord)
  if length != csize_t(count + 2 * order + 4): return -1
  let aStart = 2
  let bStart = order + 3
  let xStart = 2 * order + 4
  if input[aStart] != 1: return -1
  for index in 0 ..< order:
    if input[aStart + index + 1] < -1 or input[aStart + index + 1] > 1: return -1
  for index in 0 .. order:
    if input[bStart + index] < -1 or input[bStart + index] > 1: return -1
  for index in 0 ..< count:
    if input[xStart + index] < -16 or input[xStart + index] > 16: return -1
  let bytes = count * 8
  if bytes > 0 and (output.isNil or capacity < csize_t(bytes)): return -2
  if count == 0: return 0

  var state: array[MaxOrder, int64]
  for sampleIndex in 0 ..< count:
    let sample = input[xStart + sampleIndex]
    let value = input[bStart] * sample + (if order > 0: state[0] else: 0'i64)
    for stage in 0 ..< order:
      let nextState = if stage + 1 < order: state[stage + 1] else: 0'i64
      state[stage] = nextState + input[bStart + stage + 1] * sample - input[aStart + stage + 1] * value
    let bits = cast[uint64](value)
    for byteIndex in 0 ..< 8:
      output[sampleIndex * 8 + byteIndex] = uint8((bits shr (byteIndex * 8)) and 255'u64)
  int64(bytes)
