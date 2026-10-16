proc roundEven(x:float64,p:int):float64 =
  var scale=1.0
  for _ in 0..<p: scale*=10.0
  let y=x*scale
  var lower=int64(y)
  let fraction=y-float64(lower)
  if fraction>0.5 or (fraction==0.5 and lower mod 2 != 0):inc lower
  float64(lower)/scale
proc integration_by_simpson_approx*(v:ptr UncheckedArray[int64],n:csize_t):float64 {.cdecl,exportc:"integration_by_simpson_approx".} =
  if v.isNil or n!=3:return -1.0e300
  let a=v[0];let b=v[1];let p=v[2]
  if a < -10 or a>10 or b < -10 or b>10 or a>=b or p<0 or p>4:return -1.0e300
  let h=float64(b-a)/1000.0
  var total=float64(a*a)+float64(b*b)
  for i in 1..<1000:
    let x=float64(a)+h*float64(i)
    total+=x*x*(if i mod 2==1:4.0 else:2.0)
  total*=h/3.0
  roundEven(total,int(p))
