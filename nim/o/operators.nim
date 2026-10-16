proc putI32(outp:ptr UncheckedArray[uint8],off:int,x:int64)=
 let bits=cast[uint32](int32(x))
 for k in 0..<4:outp[off+k]=uint8((bits shr (8*k)) and 255)
proc operators*(v:ptr UncheckedArray[int64],n:csize_t,outp:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"operators".}=
 if v==nil or n<5:return -1
 let op=v[0];let ra=v[1];let ca=v[2]
 if (op!=0 and op!=1) or ra<1 or ra>16 or ca<0 or ca>16 or ra*ca>256:return -1
 let count=int(ra*ca);let pb=3+count
 if n<csize_t(pb+2):return -1
 let rb=v[pb];let cb=v[pb+1]
 if rb<1 or rb>16 or cb<0 or cb>16 or rb*cb>256 or n!=csize_t(pb+2+rb*cb):return -1
 for i in 0..<count:if v[3+i] < -1000000 or v[3+i]>1000000:return -1
 for i in 0..<int(rb*cb):if v[pb+2+i] < -1000000 or v[pb+2+i]>1000000:return -1
 if ra!=rb or ca!=cb:return -1
 if cap<csize_t(count*4) or (count>0 and outp==nil):return -2
 for i in 0..<count:putI32(outp,i*4,if op==0:v[3+i]+v[pb+2+i] else:v[3+i]-v[pb+2+i])
 int64(count)
