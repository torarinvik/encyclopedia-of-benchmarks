# Clean-room fixed-rational-scale geometric 2D pattern matching profile.
const MaxInput=186;MaxFields=289
proc put(out:ptr UncheckedArray[uint8],at:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:out[at+b]=uint8((bits shr (8*b)) and 255)
proc two_dimensional_scaled_pattern_matching*(v:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"two_dimensional_scaled_pattern_matching".}=
  if v.isNil or length<6 or length>csize_t(MaxInput):return -1
  let h0=v[0];let w0=v[1];let ph0=v[2];let pw0=v[3];let p=v[4];let q=v[5]
  if h0<1 or h0>12 or w0<1 or w0>12 or ph0<1 or ph0>6 or pw0<1 or pw0>6 or q<1 or q>8 or p<q or p>2*q:return -1
  let h=int(h0);let w=int(w0);let ph=int(ph0);let pw=int(pw0)
  if int(length)!=6+h*w+ph*pw:return -1
  for i in 0..<h*w+ph*pw:if v[6+i]<0 or v[6+i]>255:return -1
  var fields:array[MaxFields,int64];var count=1
  for r in 0..<h:
    for c in 0..<w:
      if p*int64(ph)>q*int64(h-r) or p*int64(pw)>q*int64(w-c):continue
      var matched=true
      for y in 0..<h-r:
        if (2*int64(y)+1)*q>=2*p*int64(ph):continue
        let py=int(((2*int64(y)+1)*q) div (2*p))
        for x in 0..<w-c:
          if (2*int64(x)+1)*q>=2*p*int64(pw):continue
          let px=int(((2*int64(x)+1)*q) div (2*p))
          if v[6+(r+y)*w+c+x]!=v[6+h*w+py*pw+px]:matched=false;break
        if not matched:break
      if matched:fields[count]=int64(r);fields[count+1]=int64(c);count+=2
  fields[0]=int64((count-1) div 2)
  if out.isNil or capacity<csize_t(8*count):return -2
  for i in 0..<count:put(out,8*i,fields[i])
  int64(8*count)
