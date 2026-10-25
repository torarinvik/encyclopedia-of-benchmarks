import std/math

proc cbench_rsynth_natural_glottal_sample*(input: ptr UncheckedArray[float64], n: csize_t,
    output: ptr UncheckedArray[float64], cap: csize_t): int64 {.cdecl, exportc: "cbench_rsynth_natural_glottal_sample".} =
  if input == nil or n < 1 or n > 3: return -1
  for i in 0 ..< int(n):
    if classify(input[i]) in {fcNan, fcInf, fcNegInf}: return -1
  if n != 2 or input[0] < 40.0 or input[0] > 263.0 or input[0] != trunc(input[0]) or input[1] < 0.0 or input[1] > 299.0 or input[1] != trunc(input[1]): return -1
  let nopen=int(input[0]); let index=int(input[1]); var result=0.0'f32
  if index < nopen:
    let b=(1_920_000 div (nopen*nopen)).float32
    let product=(b*nopen.float32).float32
    var a=(product.float64*0.333).float32; var wave=0.0'f32
    for i in 0 .. index: a=(a-b).float32; wave=(wave+a).float32
    result=(wave.float64*0.028).float32
  if output == nil or cap < 1: return -2
  output[0]=result.float64
  1
