proc hllGcd(a0, b0: uint64): uint64 =
  var a = a0
  var b = b0
  while b != 0:
    let r = a mod b
    a = b
    b = r
  a

proc hyperloglog_raw_estimate*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "hyperloglog_raw_estimate".} =
  if input.isNil or length < 1 or length > 130: return -1
  let raw = input[0]
  if raw < 0 or raw > 128 or length != csize_t(raw+1): return -1
  var registers: array[16,int]
  for i in 0 ..< int(raw):
    let value = input[i+1]
    if value < 0 or value > 4294967295'i64: return -1
    let hash = uint32(value)
    let bucket = int(hash shr 28)
    let suffix = hash and 0x0fffffff'u32
    var rank = 1
    var mask = 1'u32 shl 27
    while mask != 0 and (suffix and mask) == 0:
      inc rank
      mask = mask shr 1
    if rank > registers[bucket]: registers[bucket] = rank
  var sum = 0'u64
  for rank in registers: sum += 1'u64 shl (29-rank)
  var numerator = 673'u64 * 256 * (1'u64 shl 29)
  var denominator = 1000'u64 * sum
  let factor = hllGcd(numerator,denominator)
  numerator = numerator div factor
  denominator = denominator div factor
  if output.isNil or capacity < 144: return -2
  var words: array[18,uint64]
  words[0] = numerator
  words[1] = denominator
  for i in 0 ..< 16: words[i+2] = uint64(registers[i])
  var staged: array[144,uint8]
  for i in 0 ..< 18:
    for b in 0 ..< 8: staged[8*i+b] = uint8((words[i] shr (8*b)) and 255)
  for i in 0 ..< 144: output[i] = staged[i]
  144
