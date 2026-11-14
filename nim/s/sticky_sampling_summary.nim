proc putWord(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for j in 0 ..< 8:
    output[offset+j] = uint8(bits and 255'u64)
    bits = bits shr 8

proc sticky_sampling_summary*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "sticky_sampling_summary".} =
  if input == nil or length < 3 or length > 323 or input[0] < 1 or input[0] > 8 or
      input[1] < 0 or input[1] > 64 or input[2] < 0 or input[2] > 256: return -1
  let t = int(input[0])
  let n = int(input[1])
  let k = int(input[2])
  if int(length) != 3+n+k: return -1
  for i in 0 ..< n:
    if input[3+i] < 0 or input[3+i] > 15: return -1
  for i in 0 ..< k:
    if input[3+n+i] < 0 or input[3+n+i] > 255: return -1
  var counts: array[16, int64]
  var cursor = 0
  var rate = 1
  var phaseEnd = 2*t
  for i in 0 ..< n:
    if i == phaseEnd:
      rate *= 2
      phaseEnd += rate*t
      for item in 0 ..< 16:
        while counts[item] != 0:
          if cursor == k: return -1
          let draw = input[3+n+cursor]
          inc cursor
          if draw mod 2 == 1: break
          dec counts[item]
    let item = int(input[3+i])
    if counts[item] != 0: inc counts[item]
    else:
      if cursor == k: return -1
      let draw = int(input[3+n+cursor])
      inc cursor
      if draw mod rate == 0: counts[item] = 1
  if cursor != k: return -1
  var active = 0
  for count in counts:
    if count != 0: inc active
  let bytes = 8+16*active
  if output == nil or capacity < csize_t(bytes): return -2
  putWord(output, 0, int64(active))
  var offset = 8
  for item in 0 ..< 16:
    if counts[item] != 0:
      putWord(output, offset, int64(item))
      putWord(output, offset+8, counts[item])
      offset += 16
  int64(bytes)
