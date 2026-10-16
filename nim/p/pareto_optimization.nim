const MaxRows=64
const MaxCols=8
const Offset=14695981039346656037'u64
const Prime=1099511628211'u64
proc feed(h:var uint64,v:int64)=
 let bits=cast[uint64](v)
 for s in countup(0,56,8):h=(h xor uint64(uint8(bits shr s)))*%Prime
proc pareto_optimization*(a:ptr UncheckedArray[int64],len:csize_t):int64 {.cdecl,exportc:"pareto_optimization".}=
 if a.isNil or len<2 or len>csize_t(514):return -1
 let r64=a[0];let c64=a[1]
 if r64<1 or r64>MaxRows or c64<1 or c64>MaxCols or len!=csize_t(2+r64*c64):return -1
 let r=int(r64);let c=int(c64)
 for k in 0..<r*c:
  if a[2+k]<-1000 or a[2+k]>1000:return -1
 var keep:array[MaxRows,bool];var kept=0'i64
 for i in 0..<r:
  keep[i]=true
  for j in 0..<r:
   if i==j:continue
   var ge=true;var gt=false
   for x in 0..<c:
    let l=a[2+j*c+x];let v=a[2+i*c+x]
    if l<v:ge=false
    if l>v:gt=true
   if ge and (gt or j<i):keep[i]=false;break
  if keep[i]:inc kept
 var h=Offset;feed(h,kept);feed(h,c64)
 for i in 0..<r:
  if keep[i]:
   for x in 0..<c:feed(h,a[2+i*c+x])
 int64(h and 0x7fff_ffff_ffff_ffff'u64)
