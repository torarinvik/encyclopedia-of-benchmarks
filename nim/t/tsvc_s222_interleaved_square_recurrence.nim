import std/math

proc seedOk(x: float64): bool = x == -1.0 or x == -0.5 or x == 0.0 or x == 0.5 or x == 1.0

proc tsvc_s222_interleaved_square_recurrence*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s222_interleaved_square_recurrence".} =
  if input.isNil or length < 5 or length > csize_t(257): return -1
  let rn=input[0]
  if not rn.isFinite or rn != floor(rn) or rn < 1 or rn > 64: return -1
  let n=int(rn)
  if length != csize_t(1+4*n): return -1
  for i in 1 ..< 1+3*n:
    if not input[i].isFinite or input[i] != floor(input[i]) or abs(input[i]) > 2: return -1
  for i in 1+3*n ..< int(length):
    if not input[i].isFinite or not seedOk(input[i]): return -1
  let required=2*n
  if output.isNil or capacity < csize_t(required): return -2
  var a: array[64,float64]
  var e: array[64,float64]
  for i in 0 ..< n:
    a[i]=input[1+i]
    e[i]=input[1+3*n+i]
  for i in 1 ..< n:
    let product=input[1+n+i]*input[1+2*n+i]
    a[i]=a[i]+product
    e[i]=e[i-1]*e[i-1]
    a[i]=a[i]-product
  for i in 0 ..< n:
    output[i]=a[i]
    output[n+i]=e[i]
  int64(required)
