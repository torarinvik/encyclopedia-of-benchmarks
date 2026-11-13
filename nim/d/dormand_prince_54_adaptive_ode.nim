import std/math

const MaxInputLength = 7

proc exactInteger(value: float64, low, high: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf} or value < float64(low) or value > float64(high):
    return false
  float64(int64(value)) == value

proc rhs(id: int64, x, y: float64): float64 =
  case id
  of 0: y
  of 1: x+y
  of 2: sin(x)
  else: 1.0

proc trial(id: int64, x, y, h, k1: float64): tuple[y5, error, k7: float64, ok: bool] =
  let k2=rhs(id,x+h*(1.0/5.0),y+h*((1.0/5.0)*k1))
  let k3=rhs(id,x+h*(3.0/10.0),y+h*((3.0/40.0)*k1+(9.0/40.0)*k2))
  let k4=rhs(id,x+h*(4.0/5.0),y+h*((44.0/45.0)*k1-(56.0/15.0)*k2+(32.0/9.0)*k3))
  let k5=rhs(id,x+h*(8.0/9.0),y+h*((19372.0/6561.0)*k1-(25360.0/2187.0)*k2+(64448.0/6561.0)*k3-(212.0/729.0)*k4))
  let k6=rhs(id,x+h,y+h*((9017.0/3168.0)*k1-(355.0/33.0)*k2+(46732.0/5247.0)*k3+(49.0/176.0)*k4-(5103.0/18656.0)*k5))
  result.y5=y+h*((35.0/384.0)*k1+(500.0/1113.0)*k3+(125.0/192.0)*k4-(2187.0/6784.0)*k5+(11.0/84.0)*k6)
  result.k7=rhs(id,x+h,result.y5)
  result.error=h*((71.0/57600.0)*k1-(71.0/16695.0)*k3+(71.0/1920.0)*k4-(17253.0/339200.0)*k5+(22.0/525.0)*k6-(1.0/40.0)*result.k7)
  result.ok=classify(result.y5) notin {fcNan,fcInf,fcNegInf} and classify(result.error) notin {fcNan,fcInf,fcNegInf} and classify(result.k7) notin {fcNan,fcInf,fcNegInf}

proc integrate(id: int64, initialY, initialX, ending: float64, exponent, attempts: int64): tuple[status: int64, value: float64] =
  let tolerance=pow(10.0,-float64(exponent))
  var x=initialX
  var y=initialY
  var h=min((ending-initialX)/4.0,0.25)
  var k1=rhs(id,x,y)
  for _ in 0 ..< int(attempts):
    let remaining=ending-x
    if remaining<=0.0: return (1,y)
    let step=min(min(h,0.25),remaining)
    if step<=0.0 or x+step==x: return (-3,0.0)
    let candidate=trial(id,x,y,step,k1)
    if not candidate.ok: return (-3,0.0)
    let scale=tolerance*(1.0+max(abs(y),abs(candidate.y5)))
    let norm=abs(candidate.error)/scale
    if classify(norm) in {fcNan,fcInf,fcNegInf}: return (-3,0.0)
    if norm<=1.0:
      x=if step==remaining: ending else: x+step
      y=candidate.y5
      k1=candidate.k7
      if x>=ending:
        if classify(y) in {fcNan,fcInf,fcNegInf}: return (-3,0.0)
        return (1,y)
    var factor=5.0
    if norm!=0.0: factor=0.9*pow(norm,-0.2)
    h=step*min(5.0,max(0.2,factor))
  (-3,0.0)

proc dormand_prince_54_adaptive_ode*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "dormand_prince_54_adaptive_ode".} =
  if input == nil or inputLength != 6 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0],0,3) or not exactInteger(input[1],-1000,1000) or
      not exactInteger(input[2],-1000,1000) or not exactInteger(input[3],-1000,1000) or
      not exactInteger(input[4],8,9) or not exactInteger(input[5],64,128) or input[3] <= input[2]: return -1
  if output == nil or outputCapacity < 1: return -2
  let answer=integrate(int64(input[0]),input[1]/1000.0,input[2]/1000.0,input[3]/1000.0,int64(input[4]),int64(input[5]))
  if answer.status != 1: return -3
  output[0]=answer.value
  1
