const InvalidResult = -1.0e300
const MaxSamples = 16
proc gradient_boosting_regressor*(v: ptr UncheckedArray[int64], length: csize_t): float64 {.cdecl, exportc: "gradient_boosting_regressor".} =
  if v == nil or length < 8 or length > 36: return InvalidResult
  let n64=v[0]; let rounds=v[1]; let rateI=v[2]; let query=v[3]
  if n64<2 or n64>MaxSamples or rounds<1 or rounds>12 or rateI<1 or rateI>1_000_000 or length != csize_t(4+2*n64): return InvalidResult
  let n=int(n64)
  var x,y,pred,residual: array[MaxSamples,float64]
  for i in 0..<n:
    let xi=v[4+i]; let yi=v[4+n+i]
    if xi < -1000 or xi > 1000 or yi < -1_000_000 or yi > 1_000_000 or (i>0 and v[3+i]>=xi): return InvalidResult
    x[i]=float64(xi);y[i]=float64(yi)/1000.0
  if query < -1000 or query > 1000: return InvalidResult
  var mean=0.0
  for i in 0..<n: mean+=y[i]
  mean/=float64(n)
  for i in 0..<n: pred[i]=mean
  var qpred=mean
  let rate=float64(rateI)/1_000_000.0
  for r in 0..<int(rounds):
    var sum=0.0
    for i in 0..<n: residual[i]=y[i]-pred[i];sum+=residual[i]
    var constant=true
    for i in 1..<n:
      if residual[i]!=residual[0]: constant=false
    var best=1.0e300;var split=n;var left=0.0;var right=0.0
    if not constant:
      for s in 0..<(n-1):
        let nl=s+1;let nr=n-nl
        var sl=0.0;var sr=0.0
        for i in 0..<nl: sl+=residual[i]
        for i in nl..<n: sr+=residual[i]
        let lm=sl/float64(nl);let rm=sr/float64(nr)
        var err=0.0
        for i in 0..<nl:
          let d=residual[i]-lm
          err+=d*d
        for i in nl..<n:
          let d=residual[i]-rm
          err+=d*d
        if err<best: best=err;split=s;left=lm;right=rm
    if split==n:
      let leaf=sum/float64(n)
      for i in 0..<n: pred[i]+=rate*leaf
      qpred+=rate*leaf
    else:
      let threshold=(x[split]+x[split+1])/2.0
      for i in 0..<n: pred[i]+=rate*(if x[i]<=threshold:left else:right)
      qpred+=rate*(if float64(query)<=threshold:left else:right)
  return qpred
