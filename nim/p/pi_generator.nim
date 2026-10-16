proc mix(h:uint32,b:uint8):uint32 = uint32((uint64(h xor uint32(b))*16777619'u64) and 0xFFFFFFFF'u64)
proc pi_generator*(digits:int64):int64 {.cdecl,exportc:"pi_generator".} =
  if digits<0 or digits>8:return -1
  var q,r,t,k,n,m,counter=1'i64
  r=0; k=1; n=3; m=3; counter=0
  var h=2166136261'u32
  while counter!=digits+1:
    if 4*q+r-t<n*t:
      h=mix(h,uint8(48+n))
      if counter==0:h=mix(h,uint8(ord('.')))
      if digits==counter:break
      inc counter
      let nr=10*(r-n*t)
      n=(10*(3*q+r)) div t-10*n
      q*=10;r=nr
    else:
      let nr=(2*q+r)*m
      let nn=(q*(7*k)+2+r*m) div (t*m)
      q*=k;t*=m;m+=2;inc k;n=nn;r=nr
  int64(h)
