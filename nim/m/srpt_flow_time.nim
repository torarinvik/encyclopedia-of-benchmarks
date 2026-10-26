const N=12
const L=26
proc put64(output:ptr UncheckedArray[uint8],pos:int,value:int64)=
  let bits=cast[uint64](value)
  for j in 0..<8:output[pos+j]=uint8((bits shr (8*j)) and 255)
proc srpt_flow_time*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"srpt_flow_time".}=
  if input.isNil or length<csize_t(4) or length>csize_t(L):return -1
  let mr=input[0];let nr=input[1]
  if mr<1 or mr>4 or nr<1 or nr>N or int64(length)!=2+2*nr:return -1
  let machines=int(mr);let n=int(nr);var release,rem,completion:array[N,int64]
  for i in 0..<n:
    release[i]=input[2+2*i];rem[i]=input[3+2*i]
    if release[i]<0 or release[i]>50 or rem[i]<1 or rem[i]>10:return -1
  let bytes=8*(1+n);if output.isNil or capacity<csize_t(bytes):return -2
  var time=0'i64;var done=0
  while done<n:
    var chosen:array[N,bool];var selected:array[N,int];var count=0
    for machine in 0..<machines:
      var best=n
      for i in 0..<n:
        if not chosen[i] and rem[i]>0 and release[i]<=time and (best==n or rem[i]<rem[best] or (rem[i]==rem[best] and i<best)):best=i
      if best==n:break
      chosen[best]=true;selected[count]=best;inc count
    if count==0:
      var next=51'i64
      for i in 0..<n:if rem[i]>0 and release[i]<next:next=release[i]
      time=next
    else:
      inc time
      for j in 0..<count:
        let i=selected[j];dec rem[i]
        if rem[i]==0:completion[i]=time;inc done
  var total=0'i64
  for i in 0..<n:total+=completion[i]-release[i]
  put64(output,0,total);for i in 0..<n:put64(output,8*(1+i),completion[i]);int64(bytes)
