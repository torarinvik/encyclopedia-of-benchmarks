## Return a zero-based station index that completes the circuit, or -1.
proc gas_station*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "gas_station".} =
  if input.isNil or length < 1: return -2
  let n64=input[0]
  if n64 < 0 or n64 > 128: return -2
  let n=int(n64)
  if length != csize_t(2*n+1): return -2
  for i in 0..<(2*n):
    if input[i+1] < 0 or input[i+1] > 1_000_000: return -2
  var total=0'i64; var current=0'i64; var start=0
  for i in 0..<n:
    let net=input[1+i]-input[1+n+i]
    total+=net; current+=net
    if current<0: start=i+1; current=0
  if total<0: return -1
  int64(start)
