const Scale=1_000_000'i64
const MaxCount=64'i64
const MaxParsedCount=65'i64
const MaxSample=1_000_000_000'i64
const MaxDelta=1_000_000_000'i64
const MaxInputLength=133
const InvalidResult = -1.0e300
proc huber_loss_math*(v:ptr UncheckedArray[int64],n:csize_t):float64 {.cdecl,exportc:"huber_loss_math".} =
 if v==nil or n<3 or n>MaxInputLength:return InvalidResult
 let d=v[0];let ac=v[1];let pc=v[2]
 if d<0 or d>MaxDelta or ac<0 or ac>MaxParsedCount or pc<0 or pc>MaxParsedCount:return InvalidResult
 if n!=csize_t(3+ac+pc) or ac>MaxCount or pc>MaxCount:return InvalidResult
 let a=int(ac);let p=int(pc)
 for i in 0 ..< a+p:
  if v[3+i]< -MaxSample or v[3+i]>MaxSample:return InvalidResult
 let delta=float64(d)/float64(Scale);var total=0.0
 for i in 0 ..< min(a,p):
  let diff=float64(v[3+i])/float64(Scale)-float64(v[3+a+i])/float64(Scale)
  if abs(diff)<=delta:total+=0.5*(diff*diff)
  else:total+=delta*abs(diff)-0.5*delta
 total
