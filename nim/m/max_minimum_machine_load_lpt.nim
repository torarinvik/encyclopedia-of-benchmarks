const N=16
const L=18
proc put64(output:ptr UncheckedArray[uint8],pos:int,value:int64)=
  let bits=cast[uint64](value)
  for j in 0..<8:output[pos+j]=uint8((bits shr (8*j)) and 255)
proc max_minimum_machine_load_lpt*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"max_minimum_machine_load_lpt".}=
  if input.isNil or length<csize_t(3) or length>csize_t(L):return -1
  let nr=input[0];let mr=input[1]
  if nr<1 or nr>N or mr<1 or mr>4 or int64(length)!=2+nr:return -1
  let n=int(nr);let m=int(mr);var p,order,assign:array[N,int64];var loads:array[4,int64]
  for i in 0..<n:p[i]=input[2+i];if p[i]<1 or p[i]>100:return -1;order[i]=int64(i)
  let bytes=8*(1+n+m);if output.isNil or capacity<csize_t(bytes):return -2
  for i in 1..<n:
    let key=order[i];var j=i
    while j>0:
      let prev=int(order[j-1]);let k=int(key)
      if p[k]>p[prev] or (p[k]==p[prev] and k<prev):order[j]=order[j-1];dec j
      else:break
    order[j]=key
  for i in 0..<n:
    let job=int(order[i]);var machine=0
    for j in 1..<m:if loads[j]<loads[machine]:machine=j
    assign[job]=int64(machine);loads[machine]+=p[job]
  var low=loads[0];for j in 1..<m:if loads[j]<low:low=loads[j]
  put64(output,0,low);for i in 0..<n:put64(output,8*(1+i),assign[i]);for j in 0..<m:put64(output,8*(1+n+j),loads[j]);int64(bytes)
