proc static_range_sum_with_upper_bound*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or length < 2 or length > 258: return -1
  if input[0] < 1 or input[0] > 64 or input[1] < 1 or input[1] > 64: return -1
  let n = int(input[0])
  let q = int(input[1])
  if int(length) != 2+n+3*q: return -1
  var current, scratch: array[64, int64]
  for i in 0 ..< n:
    if input[2+i] < 0 or input[2+i] > 1000000000: return -1
    current[i] = input[2+i]
  for i in 0 ..< q:
    let base = 2+n+3*i
    if input[base] < 0 or input[base] > input[base+1] or input[base+1] > int64(n): return -1
    if input[base+2] < 0 or input[base+2] > 1000000000: return -1
  if output == nil or capacity < csize_t(16*q): return -2
  var counts: array[30, array[65, int]]
  var sums: array[30, array[65, int64]]
  var offsets: array[30, int]
  for level in 0 ..< 30:
    let mask = 1'i64 shl (29-level)
    for i in 0 ..< n:
      let zero = (current[i] and mask) == 0
      counts[level][i+1] = counts[level][i] + int(zero)
      sums[level][i+1] = sums[level][i]
      if zero: sums[level][i+1] += current[i]
    offsets[level] = counts[level][n]
    var z = 0
    var o = offsets[level]
    for i in 0 ..< n:
      if (current[i] and mask) == 0:
        scratch[z] = current[i]; inc z
      else:
        scratch[o] = current[i]; inc o
    for i in 0 ..< n: current[i] = scratch[i]
  for i in 0 ..< q:
    let base = 2+n+3*i
    var l = int(input[base])
    var r = int(input[base+1])
    let key = input[base+2]+1
    var count, sum: int64
    for level in 0 ..< 30:
      let zl = counts[level][l]
      let zr = counts[level][r]
      if (key and (1'i64 shl (29-level))) != 0:
        count += int64(zr-zl)
        sum += sums[level][r]-sums[level][l]
        l += offsets[level]-zl
        r += offsets[level]-zr
      else:
        l = zl; r = zr
    for byte in 0 ..< 8:
      output[16*i+byte] = uint8((count shr (8*byte)) and 255)
      output[16*i+8+byte] = uint8((sum shr (8*byte)) and 255)
  return int64(16*q)
