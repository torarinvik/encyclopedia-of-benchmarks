proc reservoir_sampling_algorithm_r*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "reservoir_sampling_algorithm_r".} =
  if input == nil or length < 2 or length > 130 or input[0] < 0 or input[0] > 64 or input[1] < 0 or input[1] > input[0]: return -1
  let n = int(input[0])
  let k = int(input[1])
  if int(length) != 2+2*n-k: return -1
  for i in 0 ..< n:
    if input[2+i] < -1000000 or input[2+i] > 1000000: return -1
  for i in k ..< n:
    if input[2+n+i-k] < 0 or input[2+n+i-k] > int64(i): return -1
  if output == nil or capacity < csize_t(8*k): return -2
  var reservoir: array[64, int64]
  for i in 0 ..< k: reservoir[i] = input[2+i]
  for i in k ..< n:
    let draw = int(input[2+n+i-k])
    if draw < k: reservoir[draw] = input[2+i]
  for i in 0 ..< k:
    var encoded = cast[uint64](reservoir[i])
    for j in 0 ..< 8:
      output[8*i+j] = uint8(encoded and 255'u64)
      encoded = encoded shr 8
  int64(8*k)
