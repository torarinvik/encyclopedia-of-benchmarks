proc put(outp:ptr UncheckedArray[uint8],i:int,x:int32)=
 let bits=cast[uint32](x)
 for k in 0..<4:outp[i*4+k]=uint8((bits shr (8*k)) and 255)
proc non_preemptive_priority_scheduling*(v:ptr UncheckedArray[int64],n:csize_t,outp:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"non_preemptive_priority_scheduling".}=
 if v==nil or n<4 or v[0]<1 or v[0]>10 or n!=csize_t(1+3*v[0]):return -1
 let count=int(v[0]);var a,b,p:array[10,int];var done:array[10,bool]
 for i in 0..<count:
  let av=v[1+3*i];let bv=v[2+3*i];let pv=v[3+3*i]
  if av<0 or av>20 or bv<1 or bv>10 or pv<0 or pv>10:return -1
  for j in 0..<i:if p[j]==int(pv):return -1
  a[i]=int(av);b[i]=int(bv);p[i]=int(pv)
 if outp==nil or cap<csize_t(count*4):return -2
 var now=0;var z=0
 while z<count:
  var pick = -1
  for i in 0..<count:
   if not done[i] and a[i]<=now and (pick<0 or p[i]<p[pick] or (p[i]==p[pick] and a[i]<a[pick])):pick=i
  if pick<0:
   var next=100000
   for i in 0..<count:if not done[i] and a[i]<next:next=a[i]
   now=next
  else:
   done[pick]=true;put(outp,z,int32(pick));z+=1;now+=b[pick]
 int64(count*4)
