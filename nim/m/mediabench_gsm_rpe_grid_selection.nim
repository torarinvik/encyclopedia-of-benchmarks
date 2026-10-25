const InputCount = 40
const MaxInputLength = 41
const OutputBytes = 112

proc asr2(value: int64): int64 =
  if value >= 0: value div 4 else: -(((-value) + 3) div 4)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc mediabench_gsm_rpe_grid_selection*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mediabench_gsm_rpe_grid_selection".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  for index in 0 ..< int(inputLength):
    if input[index] < -32768 or input[index] > 32767: return -1
  if inputLength != InputCount.csize_t: return -1

  var bestScore = -1'i64
  var bestGrid = 0'i64
  for grid in 0'i64 ..< 4:
    var sum = 0'i64
    for i in 0'i64 ..< 13:
      let scaled = asr2(input[int(grid + 3 * i)])
      sum += scaled * scaled
    let score = 2 * sum
    if score > bestScore:
      bestScore = score
      bestGrid = grid
  var staged: array[14, int64]
  staged[0] = bestGrid
  for i in 0'i64 ..< 13: staged[int(1 + i)] = input[int(bestGrid + 3 * i)]
  if output == nil or outputCapacity < OutputBytes.csize_t: return -2
  for i in 0 ..< 14: storeI64Le(output, 8 * i, staged[i])
  OutputBytes.int64
