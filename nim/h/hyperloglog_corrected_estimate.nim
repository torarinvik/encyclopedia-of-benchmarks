proc cLog(x: cdouble): cdouble {.importc: "log", header: "<math.h>".}
proc cLog1p(x: cdouble): cdouble {.importc: "log1p", header: "<math.h>".}

proc hyperloglog_corrected_estimate*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "hyperloglog_corrected_estimate".} =
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
  var zeros = 0
  for rank in registers:
    sum += 1'u64 shl (29-rank)
    if rank == 0: inc zeros
  var estimate = 673.0*256.0*536870912.0/(1000.0*float64(sum))
  let universe = 4294967296.0
  if estimate <= 40.0 and zeros != 0:
    estimate = 16.0*cLog(16.0/float64(zeros))
  elif estimate > universe/30.0:
    if estimate >= universe: return -3
    estimate = -universe*cLog1p(-estimate/universe)
  if output.isNil or capacity < 8: return -2
  let bits = cast[uint64](estimate)
  var staged: array[8,uint8]
  for b in 0 ..< 8: staged[b] = uint8((bits shr (8*b)) and 255)
  for b in 0 ..< 8: output[b] = staged[b]
  8
