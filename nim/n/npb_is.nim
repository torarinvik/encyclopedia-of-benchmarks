## Independent port of the class-W NAS Parallel Benchmarks Integer Sort.
const TotalKeys = 1 shl 20
const MaxKey = 1 shl 16
const NumBuckets = 1 shl 10
const MaxIterations = 10
const MaxPasses = 10
const TestIndices: array[5, uint32] = [357773'u32, 934767'u32, 875723'u32, 898999'u32, 404505'u32]
const BaselineRanks: array[5, uint32] = [1249'u32, 11698'u32, 1039987'u32, 1043896'u32, 1048018'u32]

var keyArray: array[TotalKeys, uint32]
var keyBuff2: array[TotalKeys, uint32]
var keyBuff1: array[MaxKey, uint32]
var bucketSize: array[NumBuckets, uint32]
var bucketPtrs: array[NumBuckets, uint32]

proc nextState(state: uint64): uint64 =
  const Two23 = 1'u64 shl 23
  const LowMask = Two23 - 1
  const StateMask = (1'u64 shl 46) - 1
  const MultiplierHigh = 1220703125'u64 div Two23
  const MultiplierLow = 1220703125'u64 mod Two23
  let x1 = state shr 23
  let x2 = state and LowMask
  let t1 = MultiplierHigh * x2 + MultiplierLow * x1
  let z = t1 and LowMask
  ((z shl 23) + MultiplierLow * x2) and StateMask

proc generateKeys() =
  var state = 314159265'u64
  for index in 0 ..< TotalKeys:
    var fourStateSum = 0'u64
    for draw in 0 ..< 4:
      state = nextState(state)
      fourStateSum += state
    keyArray[index] = uint32(fourStateSum shr 32)

proc expectedRank(index: int, iteration: uint32): uint32 =
  if index < 2:
    return uint32(int64(BaselineRanks[index]) + int64(iteration) - 2)
  BaselineRanks[index] - iteration

proc decimalWidth(value: uint32): int =
  var remaining = value
  result = 1
  while remaining >= 10'u32:
    remaining = remaining div 10'u32
    inc result

proc requiredOutputBytes(passCount: uint32): int =
  for iteration in 1'u32 .. passCount:
    for test in 0 ..< 5:
      result += decimalWidth(expectedRank(test, iteration))
    result += 5 # Four commas and LF.
  result += decimalWidth(5'u32 * passCount + 1'u32) + 1

proc appendDecimal(value: uint32, output: ptr UncheckedArray[uint8], position: var int) =
  var reversed: array[10, uint8]
  var count = 0
  var remaining = value
  while true:
    reversed[count] = uint8(48'u32 + remaining mod 10'u32)
    inc count
    remaining = remaining div 10'u32
    if remaining == 0: break
  while count > 0:
    dec count
    output[position] = reversed[count]
    inc position

proc rankPass(iteration: uint32, partials: var array[5, uint32]) =
  keyArray[int(iteration)] = iteration
  keyArray[int(iteration + uint32(MaxIterations))] = uint32(MaxKey) - iteration
  for bucket in 0 ..< NumBuckets: bucketSize[bucket] = 0
  for index in 0 ..< TotalKeys: inc bucketSize[int(keyArray[index] shr 6)]
  bucketPtrs[0] = 0
  for bucket in 1 ..< NumBuckets:
    bucketPtrs[bucket] = bucketPtrs[bucket - 1] + bucketSize[bucket - 1]
  for index in 0 ..< TotalKeys:
    let key = keyArray[index]
    let bucket = int(key shr 6)
    keyBuff2[int(bucketPtrs[bucket])] = key
    inc bucketPtrs[bucket]
  for key in 0 ..< MaxKey: keyBuff1[key] = 0
  for index in 0 ..< TotalKeys: inc keyBuff1[int(keyBuff2[index])]
  for key in 1 ..< MaxKey: keyBuff1[key] += keyBuff1[key - 1]
  for test in 0 ..< 5:
    let key = keyArray[int(TestIndices[test])]
    partials[test] = if key == 0: 0'u32 else: keyBuff1[int(key - 1)]

proc fullVerify(): bool =
  for index in 0 ..< TotalKeys:
    let key = keyBuff2[index]
    dec keyBuff1[int(key)]
    keyArray[int(keyBuff1[int(key)])] = key
  for index in 1 ..< TotalKeys:
    if keyArray[index - 1] > keyArray[index]: return false
  true

proc npb_is*(passCount: int64, output: ptr UncheckedArray[uint8],
             outputCapacity: csize_t): int64 {.cdecl, exportc: "npb_is".} =
  if passCount < 1 or passCount > MaxPasses: return -1
  let passes = uint32(passCount)
  let required = requiredOutputBytes(passes)
  if output.isNil or outputCapacity < csize_t(required): return -2

  generateKeys()
  var partials: array[5, uint32]
  rankPass(1'u32, partials) # Untimed source warm-up.
  var passedVerification = 0'u32
  var position = 0
  for iteration in 1'u32 .. passes:
    rankPass(iteration, partials)
    for test in 0 ..< 5:
      if partials[test] == expectedRank(test, iteration): inc passedVerification
      appendDecimal(partials[test], output, position)
      if test + 1 < 5:
        output[position] = uint8(ord(','))
        inc position
    output[position] = uint8(ord('\n'))
    inc position
  if fullVerify(): inc passedVerification
  if passedVerification != 5'u32 * passes + 1'u32: passedVerification = 0
  appendDecimal(passedVerification, output, position)
  output[position] = uint8(ord('\n'))
  inc position
  int64(position)
