proc putDouble(outp:ptr UncheckedArray[uint8],x:float64)=
 let bits=cast[uint64](x)
 for k in 0..<8:outp[k]=uint8((bits shr (8*k)) and 255)
proc orbital_transfer_work*(v:ptr UncheckedArray[int64],n:csize_t,outp:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"orbital_transfer_work".}=
 if v==nil or n!=4:return -1
 let a=v[0];let b=v[1];let r1=v[2];let r2=v[3]
 if a < -1000000000 or a>1000000000 or b < -1000000 or b>1000000 or r1<1 or r1>1000000000 or r2<1 or r2>1000000000:return -1
 if outp==nil or cap<8:return -2
 let work=(6.67430e-11*float64(a)*float64(b)/2.0)*(1.0/float64(r1)-1.0/float64(r2))
 putDouble(outp,work);8
