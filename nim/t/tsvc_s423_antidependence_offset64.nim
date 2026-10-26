proc tsvc_s423_antidependence_offset64*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tsvc_s423_antidependence_offset64".} =
  if input.isNil or length < 130 or length > csize_t(193): return -1
  if input[0] < 65 or input[0] > 128: return -1
  let n = int(input[0])
  if length != csize_t(n + 65): return -1
  var a: array[128, int64]
  var x: array[192, int64]
  for i in 0 ..< n:
    a[i] = input[1+i]
    if a[i] < 0 or a[i] > 2: return -1
  for i in 0 ..< 64:
    x[i] = input[1+n+i]
    if x[i] < 0 or x[i] > 2: return -1
  for i in 64 ..< n+64: x[i] = 1
  for i in 0 ..< n-1: x[i+1] = x[i+64] + a[i]
  var total: int64 = 0
  for i in 0 ..< n: total += x[i]
  total
