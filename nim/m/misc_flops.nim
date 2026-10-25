const InvalidResult = -1.0e300
const A1 = -0.1666666666671334
const A2 = 0.833333333809067e-2
const A3 = 0.198412715551283e-3
const A4 = 0.27557589750762e-5
const A5 = 0.2507059876207e-7
const A6 = 0.164105986683e-9
const B1 = -0.4999999999982
const B2 = 0.4166666664651e-1
const B3 = -0.1388888805755e-2
const B4 = 0.24801428034e-4
const B5 = -0.2754213324e-6
const B6 = 0.20189405e-8
const D1 = 0.3999999946405e-1
const D2 = 0.96e-3
const D3 = 0.1233153e-5
const E2 = 0.48e-3
const E3 = 0.411051e-6

proc sinPolyLegacy(w: float64): float64 =
  var value = A6
  value = value*w + A5
  value = value*w + A4
  value = value*w + A3
  value = value*w + A2
  value = value*w + A1
  value*w + 1.0

proc sinPolyAlternating(w: float64): float64 =
  var value = A6
  value = value*w - A5
  value = value*w + A4
  value = value*w - A3
  value = value*w + A2
  value = value*w + A1
  value*w + 1.0

proc cosPoly(w: float64): float64 =
  var value = B6
  value = value*w + B5
  value = value*w + B4
  value = value*w + B3
  value = value*w + B2
  value = value*w + B1
  value*w + 1.0

proc misc_flops*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "misc_flops".} =
  if values == nil or length != 2: return InvalidResult
  let moduleId = values[0]
  let steps = values[1]
  if moduleId < 1 or moduleId > 8 or steps < 2 or steps > 128: return InvalidResult
  let pi = 3.14159265358979323846
  var sum = 0.0
  var answer = 0.0
  var x = 0.0
  var u = 0.0
  var w = 0.0
  if moduleId == 1:
    let n = 2 * steps
    let dx = 1.0 / float64(n)
    var v = 0.0
    for i in 1 ..< n:
      v += 1.0
      u = v * dx
      sum += (D1 + u*(D2 + u*D3)) / (1.0 + u*(D1 + u*(E2 + u*E3)))
    let endpoint = (D1 + D2 + D3) / (1.0 + D1 + E2 + E3)
    answer = 1.0 / (dx * (endpoint + D1 + 2.0*sum) / 2.0)
  elif moduleId == 2:
    var sign = -5.0
    var partial = -1.0
    for _ in 0 ..< steps:
      sign = -sign
      partial += sign
    var v = 0.0
    var reciprocalSum = 0.0
    u = partial
    x = 0.0
    for _ in 0 ..< steps:
      sign = -sign
      partial += sign
      u += 2.0
      x = x + (sign - u)
      v = v - sign*u
      reciprocalSum = reciprocalSum + sign/u
    let estimate = 4.0*reciprocalSum/5.0 + 5.0/v
    answer = estimate - 31.25/(v*v*v)
  elif moduleId == 3:
    let dx = pi / (3.0*float64(steps))
    var v = 0.0
    for i in 1 ..< steps:
      v += 1.0
      u = v*dx
      w = u*u
      sum += u*sinPolyAlternating(w)
    u = pi/3.0
    w = u*u
    answer = dx*(u*sinPolyAlternating(w) + 2.0*sum)/2.0
  elif moduleId == 4:
    let dx = pi / (3.0*float64(steps))
    for i in 1 ..< steps:
      u = float64(i)*dx
      w = u*u
      sum += w*(w*(w*(w*(w*(B6*w+B5)+B4)+B3)+B2)+B1)+1.0
    u = pi/3.0
    w = u*u
    let endpoint = w*(w*(w*(w*(w*(B6*w+B5)+B4)+B3)+B2)+B1)+1.0
    answer = dx*(endpoint+1.0+2.0*sum)/2.0
  elif moduleId == 5:
    let dx = pi / (3.0*float64(steps))
    for i in 1 ..< steps:
      u = float64(i)*dx
      w = u*u
      sum += (u*sinPolyLegacy(w))/cosPoly(w)
    u = pi/3.0
    w = u*u
    answer = dx*(u*sinPolyLegacy(w)/cosPoly(w)+2.0*sum)/2.0
  elif moduleId == 6:
    let dx = pi / (4.0*float64(steps))
    for i in 1 ..< steps:
      u = float64(i)*dx
      w = u*u
      sum += (u*sinPolyLegacy(w))*cosPoly(w)
    u = pi/4.0
    w = u*u
    answer = dx*((u*sinPolyLegacy(w))*cosPoly(w)+2.0*sum)/2.0
  elif moduleId == 7:
    let finish = 102.3321513995275
    let dx = finish/float64(steps)
    for i in 1 ..< steps:
      x = float64(i)*dx
      u = x*x
      sum = sum - 1.0/(x+1.0) - x/(u+1.0) - u/(x*u+1.0)
    x = finish
    u = x*x
    let endpoint = -1.0 - 1.0/(x+1.0) - x/(u+1.0) - u/(x*u+1.0)
    answer = 18.0*dx*(endpoint+2.0*sum)
  else:
    let dx = pi / (3.0*float64(steps))
    for i in 1 ..< steps:
      u = float64(i)*dx
      w = u*u
      let cosine = cosPoly(w)
      sum += cosine*cosine*u*sinPolyLegacy(w)
    u = pi/3.0
    w = u*u
    let cosine = cosPoly(w)
    answer = dx*((u*sinPolyLegacy(w))*cosine*cosine+2.0*sum)/2.0
  answer
