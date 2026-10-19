const MinExperiments = 1'i64
const MaxExperiments = 1_000'i64
const MaxOutputBytes = 123
const Mask48 = 0xFFFFFFFFFFFF'u64
const Mask24 = 0xFFFFFF'u64

proc nextLrand48(state: var uint64): uint32 =
  let low = state and Mask24
  let high = state shr 24
  let highProduct = (high * 0xECE66D'u64) and Mask24
  state = (low * 0x5DEECE66D'u64 + (highProduct shl 24) + 0xB'u64) and Mask48
  uint32(state shr 17)

proc differentExperiment(randomState: var uint64, freeState: var array[10, uint8]): bool =
  var faultyState = freeState
  for _ in 0 ..< 10:
    let savedFree = freeState[0]
    let savedFaulty = faultyState[0]
    var randomWord = nextLrand48(randomState)
    for cell in 0 ..< 9:
      freeState[cell] = uint8((uint32(freeState[cell + 1]) + randomWord) and 1'u32)
      let randomProbability = nextLrand48(randomState)
      if randomProbability mod 1000'u32 < 250'u32: randomWord = randomWord xor 1'u32
      faultyState[cell] = uint8((uint32(faultyState[cell + 1]) + randomWord) and 1'u32)
      randomWord = randomWord shr 1
    randomWord = nextLrand48(randomState)
    freeState[9] = uint8((uint32(savedFree) + randomWord) and 1'u32)
    let randomProbability = nextLrand48(randomState)
    if randomProbability mod 10_000'u32 < 2_500'u32: randomWord = randomWord xor 1'u32
    faultyState[9] = uint8((uint32(savedFaulty) + randomWord) and 1'u32)
  freeState != faultyState

proc appendText(buffer: var array[MaxOutputBytes, uint8], used: var int, text: string) =
  for ch in text:
    buffer[used] = uint8(ord(ch))
    inc used

proc appendUnsigned(buffer: var array[MaxOutputBytes, uint8], used: var int, value: uint64) =
  var remaining = value
  var reverse: array[24, uint8]
  var count = 0
  while true:
    reverse[count] = uint8(48'u64 + remaining mod 10'u64)
    inc count
    remaining = remaining div 10'u64
    if remaining == 0: break
  while count > 0:
    dec count
    buffer[used] = reverse[count]
    inc used

proc appendProbability(buffer: var array[MaxOutputBytes, uint8], used: var int,
                       sameCount, experiments: uint64) =
  var mantissa = 0'u64
  var exponent = 0
  if sameCount != 0:
    var scale = 1'u64
    while sameCount * scale < experiments:
      scale *= 10'u64
      dec exponent
    let numerator = sameCount * scale * 100_000_000'u64
    mantissa = numerator div experiments
    let remainder = numerator mod experiments
    if 2'u64 * remainder > experiments or
        (2'u64 * remainder == experiments and (mantissa and 1'u64) != 0):
      inc mantissa
    if mantissa == 1_000_000_000'u64:
      mantissa = 100_000_000'u64
      inc exponent
  let whole = mantissa div 100_000_000'u64
  var fraction = mantissa mod 100_000_000'u64
  buffer[used] = uint8(48'u64 + whole)
  inc used
  buffer[used] = uint8(ord('.'))
  inc used
  var place = 10_000_000'u64
  for _ in 0 ..< 8:
    buffer[used] = uint8(48'u64 + fraction div place)
    inc used
    fraction = fraction mod place
    place = place div 10'u64
  buffer[used] = uint8(ord('e'))
  inc used
  buffer[used] = uint8(ord(if exponent < 0: '-' else: '+'))
  inc used
  let absoluteExponent = abs(exponent)
  buffer[used] = uint8(48 + absoluteExponent div 10)
  inc used
  buffer[used] = uint8(48 + absoluteExponent mod 10)
  inc used

proc mcgill_misr*(experiments: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "mcgill_misr".} =
  if experiments < MinExperiments or experiments > MaxExperiments: return -1
  if output.isNil: return -2

  var randomState = 1'u64
  var freeState = [0'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8]
  var differentCount = 0'u64
  for _ in 0 ..< int(experiments):
    if differentExperiment(randomState, freeState): inc differentCount

  var staged: array[MaxOutputBytes, uint8]
  var used = 0
  appendText(staged, used, "reg_len #_vect prob #_tms struct seed1 seed2 seed3 Prob same output\n ")
  appendText(staged, used, "10 10 2.500e-01 ")
  appendUnsigned(staged, used, uint64(experiments))
  appendText(staged, used, " 1000000000 1 0 0 ")
  appendProbability(staged, used, uint64(experiments) - differentCount, uint64(experiments))
  staged[used] = uint8(10)
  inc used

  if outputCapacity < csize_t(used): return -2
  for index in 0 ..< used: output[index] = staged[index]
  int64(used)
