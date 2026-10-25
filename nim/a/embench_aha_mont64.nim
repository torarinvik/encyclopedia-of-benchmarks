proc wide(a,b:uint64):(uint64,uint64)=
  const mask=0xffffffff'u64
  let a0=a and mask;let a1=a shr 32;let b0=b and mask;let b1=b shr 32
  let p00=a0*b0;let p01=a0*b1;let p10=a1*b0;let p11=a1*b1
  var lo=p00;var old=lo;lo=lo+(p01 shl 32);var hi=p11+(p01 shr 32);if lo<old:inc hi;old=lo;lo=lo+(p10 shl 32);hi=hi+(p10 shr 32);if lo<old:inc hi
  (hi,lo)
proc mont(a,b,m,np:uint64):uint64=
  let (thi,tlo)=wide(a,b);let (tmmhi,tmmlo)=wide(tlo*np,m);let ulo=tlo+tmmlo;var uhi=thi+tmmhi;if ulo<tlo:inc uhi;let ov=uhi<thi or (uhi==thi and ulo<tlo);if ov or uhi>=m: uhi-m else: uhi
proc nprime(m:uint64):uint64=
  var x=1'u64
  for _ in 0..<6:x=x*(2-m*x)
  0'u64-x
proc embench_aha_mont64*(values:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"embench_aha_mont64".}=
  if values.isNil or length!=3:return -1
  if values[0]<0 or values[1]<0 or values[2]<3 or (values[2] and 1)==0:return -1
  let a=uint64(values[0]);let b=uint64(values[1]);let m=uint64(values[2])
  if a>=m or b>=m:return -1
  int64(mont(a,b,m,nprime(m)))
