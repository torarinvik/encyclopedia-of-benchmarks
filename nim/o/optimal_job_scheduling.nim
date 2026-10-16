proc optimal_job_scheduling*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "optimal_job_scheduling".} =
  if values == nil or length < 4 or length > 194 or values[0] < 1 or values[0] > 16 or values[1] < 1 or values[1] > 8: return -1
  let p = int(values[0]); let m = int(values[1])
  if int(length) != 2 + p*m + m*m: return -1
  for i in 2 ..< int(length):
    if values[i] < 0 or values[i] > 1000: return -1
  var cost: array[128, int]
  for j in 0 ..< m: cost[j] = int(values[2+j])
  for i in 1 ..< p:
    for j in 0 ..< m:
      var best = high(int)
      for k in 0 ..< m:
        let candidate = cost[(i-1)*m+k] + int(values[2+p*m+k*m+j]) + int(values[2+i*m+j])
        if candidate < best: best = candidate
      cost[i*m+j] = best
  var result = ""
  for i in 0 ..< p:
    if i > 0: result.add('\n')
    for j in 0 ..< m:
      if j > 0: result.add(',')
      result.add($cost[i*m+j])
  if result.len > int(capacity) or (result.len > 0 and output == nil): return -2
  for i in 0 ..< result.len: output[i] = uint8(ord(result[i]))
  int64(result.len)
