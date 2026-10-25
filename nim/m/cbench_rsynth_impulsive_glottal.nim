import std/math

proc cbench_rsynth_impulsive_glottal_sample*(input: ptr UncheckedArray[float64], n: csize_t,
    output: ptr UncheckedArray[float64], cap: csize_t): int64 {.cdecl, exportc: "cbench_rsynth_impulsive_glottal_sample".} =
  if input == nil or n < 1 or n > 3: return -1
  for i in 0 ..< int(n):
    if classify(input[i]) in {fcNan, fcInf, fcNegInf}: return -1
  if n != 2 or input[0] < 40 or input[0] > 263 or input[0] != trunc(input[0]) or input[1] < 0 or input[1] > 299 or input[1] != trunc(input[1]): return -1
  let open=int(input[0]);let target=int(input[1]);let rate=8000
  let minusPi=(-PI/float64(rate)).float32
  let twoPi=(-2.0*float64(minusPi)).float32
  let bw=rate div open
  let r=(exp(float64(minusPi)*float64(bw))).float32
  let c=(-(r*r)).float32
  let b=(float64(r)*cos(float64(twoPi)*0.0)*2.0).float32
  var a=(1.0-float64(b)-float64(c)).float32
  let t=(float64(open)*0.00833).float32
  a=(a*(t*t)).float32
  var p1=0.0'f32;var p2=0.0'f32;var result=0.0'f32
  for i in 0 .. target:
    let impulse=if i==1:13_000_000.0'f32 elif i==2: -13_000_000.0'f32 else:0.0'f32
    var x=(a*impulse).float32;x=(x+(b*p1).float32).float32;x=(x+(c*p2).float32).float32
    p2=p1;p1=x;result=x
  if output==nil or cap<1:return -2
  output[0]=float64(result)
  1
