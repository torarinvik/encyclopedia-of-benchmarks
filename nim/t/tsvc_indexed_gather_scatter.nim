const MaxN = 16
const MaxInputLength = 2 + 5 * MaxN
const MaxOperand = 1000000'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc boundedOperand(value: int64): bool =
  value >= -MaxOperand and value <= MaxOperand

proc tsvc_indexed_gather_scatter*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_indexed_gather_scatter".} =
  if input == nil or length < 6 or length > csize_t(MaxInputLength): return -1
  let mode = input[0]
  let nValue = input[1]
  if (mode != 491 and mode != 4113) or nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  let arraysPerIndex = if mode == 491: 5 else: 4
  if int(length) != 2 + arraysPerIndex * n: return -1

  let indexStart = 2
  let aStart = indexStart + n
  let bStart = aStart + n
  let cStart = bStart + n
  let dStart = cStart + n
  var state: array[MaxN, int64]
  for i in 0 ..< n:
    let index = input[indexStart + i]
    if index < 0 or index >= nValue: return -1
    state[i] = input[aStart + i]
    if not boundedOperand(input[bStart + i]) or not boundedOperand(input[cStart + i]): return -1
    if mode == 491 and not boundedOperand(input[dStart + i]): return -1
  if output == nil or outputCapacity < csize_t(8 * n): return -2

  for i in 0 ..< n:
    let index = int(input[indexStart + i])
    if mode == 491:
      state[index] = input[bStart + i] + input[cStart + i] * input[dStart + i]
    else:
      state[index] = input[bStart + index] + input[cStart + i]
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, state[i])
  int64(n)
