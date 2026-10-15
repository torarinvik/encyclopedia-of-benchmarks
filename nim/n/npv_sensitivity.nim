## Evaluate net present value for each supplied discount rate.
import std/math
proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits=cast[uint64](value)
  for b in 0..<8: output[offset+b]=uint8((bits shr (8*b)) and 0xFF'u64)
proc npv_sensitivity*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "npv_sensitivity".} =
  if input.isNil or length < 2: return -1
  let n64=input[0];let rates64=input[1]
  if n64<0 or n64>64 or rates64<0 or rates64>32: return -1
  let n=int(n64);let rates=int(rates64)
  if length != csize_t(2+n+rates): return -1
  for t in 0..<n: if input[t+2] < -1_000_000 or input[t+2] > 1_000_000: return -1
  for r in 0..<rates: if input[2+n+r] < 0 or input[2+n+r] > 1000: return -1
  if capacity < csize_t(rates*8) or (rates>0 and output.isNil): return -2
  for r in 0..<rates:
    let rate=float64(input[2+n+r])/10000.0
    var total=0.0
    for t in 0..<n:
      let term=float64(input[2+t])/pow(1.0+rate,float64(t))
      total=total+term
    putF64Le(output,r*8,total)
  int64(rates*8)
