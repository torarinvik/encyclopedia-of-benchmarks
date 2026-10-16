## Two-sided CUSUM detector over a bounded integer-valued input domain.
proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[offset+b] = uint8((bits shr (8*b)) and 0xFF'u64)
proc cusum_detector*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "cusum_detector".} =
  if input.isNil or length < 5: return -1
  let n64 = input[0]
  if n64 < 0 or n64 > 128: return -1
  let n = int(n64)
  if length != csize_t(n+5): return -1
  let target=input[1]; let sigma=input[2]; let allowance=input[3]; let threshold=input[4]
  if target < -1000 or target > 1000 or sigma < 1 or sigma > 1000 or allowance < 0 or allowance > 1000 or threshold < 1 or threshold > 1000: return -1
  for i in 0..<n:
    if input[5+i] < -1000 or input[5+i] > 1000: return -1
  if capacity < csize_t(n*8) or (n > 0 and output.isNil): return -2
  var upper=0.0; var lower=0.0
  for i in 0..<n:
    let z=(float64(input[5+i])-float64(target))/float64(sigma)
    upper=max(0.0,upper+z-float64(allowance))
    lower=max(0.0,lower-z-float64(allowance))
    var signal:int64=0
    if upper>float64(threshold): signal=1
    elif lower>float64(threshold): signal = -1
    if signal != 0: upper=0.0; lower=0.0
    putI64Le(output,i*8,signal)
  int64(n*8)
