const MaxLength=64
const MaxAbsValue=1_000_000'i64
const InvalidResult = -1.0e300
type I64Input = ptr UncheckedArray[int64]
proc welfords_variance*(values:I64Input,length:csize_t):float64 {.cdecl,exportc:"welfords_variance".}=
 if values==nil or length<2 or length>MaxLength:return InvalidResult
 var mean=0.0;var m2=0.0
 for i in 0..<int(length):
  let x=values[i]
  if x < -MaxAbsValue or x > MaxAbsValue:return InvalidResult
  let delta=float64(x)-mean
  mean+=delta/float64(i+1)
  m2+=delta*(float64(x)-mean)
 m2/float64(length-1)
