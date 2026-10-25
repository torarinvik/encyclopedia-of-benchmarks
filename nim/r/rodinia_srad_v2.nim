import std/math

const
  Pixels = 256
  InputCount = 258
  LambdaMinBits = 0x3c23d70a'u32
  LambdaMaxBits = 0x3dcccccd'u32
  Q0MinBits = 0x3c23d70a'u32
  Q0MaxBits = 0x3f800000'u32
  JMinBits = 0x3f800000'u32
  JMaxBits = 0x3fa00000'u32

proc add32(a,b:float32):float32 =
  let value:float32 = a+b
  value
proc sub32(a,b:float32):float32 =
  let value:float32 = a-b
  value
proc mul32(a,b:float32):float32 =
  let value:float32 = a*b
  value
proc div32(a,b:float32):float32 =
  let value:float32 = a/b
  value

proc rodinia_srad_v2*(values:ptr UncheckedArray[int64],length:csize_t):int64
    {.cdecl,exportc:"rodinia_srad_v2".} =
  if values.isNil or length != csize_t(InputCount): return -1
  for i in 0 ..< InputCount:
    if values[i] < 0 or uint64(values[i]) > 0xffff_ffff'u64: return -1
  let lambdaBits = uint32(values[0])
  let q0Bits = uint32(values[1])
  if lambdaBits < LambdaMinBits or lambdaBits > LambdaMaxBits or
      q0Bits < Q0MinBits or q0Bits > Q0MaxBits: return -1
  let lambda = cast[float32](lambdaBits)
  let q0sqr = cast[float32](q0Bits)
  var image:array[Pixels,float32]
  var coeff,north,south,west,east:array[Pixels,float32]
  for i in 0 ..< Pixels:
    let bits=uint32(values[i+2])
    if bits < JMinBits or bits > JMaxBits: return -1
    image[i]=cast[float32](bits)

  for row in 0 ..< 16:
    for col in 0 ..< 16:
      let i=row*16+col
      let jc=image[i]
      let n=sub32(image[(if row>0:row-1 else:row)*16+col],jc)
      let s=sub32(image[(if row<15:row+1 else:row)*16+col],jc)
      let w=sub32(image[row*16+(if col>0:col-1 else:col)],jc)
      let e=sub32(image[row*16+(if col<15:col+1 else:col)],jc)
      north[i]=n;south[i]=s;west[i]=w;east[i]=e
      var gradient=add32(add32(add32(mul32(n,n),mul32(s,s)),mul32(w,w)),mul32(e,e))
      gradient=div32(gradient,mul32(jc,jc))
      let laplacian=div32(add32(add32(add32(n,s),w),e),jc)
      let lapSq=mul32(laplacian,laplacian)
      let num=float32(0.5*float64(gradient)-(1.0/16.0)*float64(lapSq))
      var den=float32(1.0+0.25*float64(laplacian))
      if den==0.0'f32:return -1
      let qsqr=div32(num,mul32(den,den))
      den=div32(sub32(qsqr,q0sqr),mul32(q0sqr,add32(1.0'f32,q0sqr)))
      if den == -1.0'f32:return -1
      var c=float32(1.0/(1.0+float64(den)))
      if classify(float64(c)) in {fcNan,fcInf,fcNegInf}:return -1
      if c<0.0'f32:c=0.0'f32
      elif c>1.0'f32:c=1.0'f32
      coeff[i]=c

  var checksum=0'i64
  for row in 0 ..< 16:
    for col in 0 ..< 16:
      let i=row*16+col
      let cc=coeff[i]
      let cs=coeff[(if row<15:row+1 else:row)*16+col]
      let ce=coeff[row*16+(if col<15:col+1 else:col)]
      let divergence=add32(add32(add32(mul32(cc,north[i]),mul32(cs,south[i])),mul32(cc,west[i])),mul32(ce,east[i]))
      let updated=float32(float64(image[i])+0.25*float64(lambda)*float64(divergence))
      if classify(float64(updated)) in {fcNan,fcInf,fcNegInf} or updated<0.0'f32:return -1
      checksum+=int64(float64(updated)*1_000_000.0+0.5)
  checksum
