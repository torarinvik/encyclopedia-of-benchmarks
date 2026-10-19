import std/math
const MaxN=16
const InvalidResult = -1e300
proc term(x,omega:float64,select:int):float64=
  let base=pow(x+1.0,x)
  if select==0:return base
  if select==1:return base*cos(omega*x)
  base*sin(omega*x)
proc integrate(omega:float64,select:int):float64=
  var x=0.0
  let dx=(2.0-0.0)/200.0
  var value=term(0.0,omega,select)/2.0
  var steps=200
  if steps!=1:
    dec steps
    while true:
      dec steps
      if steps==0:break
      x+=dx
      value+=term(x,omega,select)
  (value+term(2.0,omega,select)/2.0)*dx
proc nbench_fourier_coefficients*(input:ptr UncheckedArray[int64],length:csize_t):float64 {.cdecl,exportc:"nbench_fourier_coefficients".}=
  if input==nil or length<1 or length>2:return InvalidResult
  let raw=input[0]
  if raw<1 or raw>MaxN or length!=1:return InvalidResult
  let n=int(raw)
  var a:array[MaxN,float64]
  var b:array[MaxN,float64]
  a[0]=integrate(0.0,0)/2.0
  for i in 1 ..< n:
    let omega=3.1415926535897932*float64(i)
    a[i]=integrate(omega,1)
    b[i]=integrate(omega,2)
  var checksum=0.0
  for i in 0 ..< n:checksum+=float64(i+1)*a[i]
  for i in 1 ..< n:checksum+=float64(i)*b[i]
  if checksum.classify.isFinite:checksum else:InvalidResult
