proc putWord(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for j in 0 ..< 8:
    output[offset+j] = uint8(bits and 255'u64)
    bits = bits shr 8

proc lossy_counting_summary*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "lossy_counting_summary".} =
  if input == nil or length < 2 or length > 66 or input[0] < 2 or input[0] > 16 or input[1] < 0 or input[1] > 64: return -1
  let width = int(input[0])
  let n = int(input[1])
  if int(length) != 2+n: return -1
  for i in 0 ..< n:
    if input[2+i] < 0 or input[2+i] > 15: return -1
  var count, error: array[16, int64]
  for i in 0 ..< n:
    let item = int(input[2+i])
    let bucket = int64(i div width+1)
    if count[item] == 0: error[item] = bucket-1
    inc count[item]
    if (i+1) mod width == 0:
      for j in 0 ..< 16:
        if count[j] != 0 and count[j]+error[j] <= bucket:
          count[j] = 0
          error[j] = 0
  var active = 0
  for i in 0 ..< 16:
    if count[i] != 0: inc active
  let bytes = 8+24*active
  if output == nil or capacity < csize_t(bytes): return -2
  putWord(output, 0, int64(active))
  var offset = 8
  for i in 0 ..< 16:
    if count[i] != 0:
      putWord(output, offset, int64(i))
      putWord(output, offset+8, count[i])
      putWord(output, offset+16, error[i])
      offset += 24
  int64(bytes)
