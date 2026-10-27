const MaxN=8
const MaxInput=82
const InputScale=1_000_000'i64

proc gcd(a0,b0:int64):int64=
  var a=a0;var b=b0
  while b!=0:
    let r=a mod b;a=b;b=r
  a

proc put64(output:ptr UncheckedArray[uint8],pos:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[pos+b]=uint8((bits shr (8*b)) and 255)

proc sensor_energy_balance_estimator_trace*(input:ptr UncheckedArray[int64],length:csize_t,
    output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"sensor_energy_balance_estimator_trace".}=
  if input.isNil or length<4 or length>csize_t(MaxInput):return -1
  let n64=input[0];let h64=input[1]
  if n64<1 or n64>8 or h64<1 or h64>8 or int64(length)!=2+n64+h64+n64*h64:return -1
  let n=int(n64);let h=int(h64);var lambda:array[MaxN,int64];var sum=0'i64
  for i in 0..<n:
    lambda[i]=input[2+i]
    if lambda[i]<0 or lambda[i]>InputScale:return -1
    sum+=lambda[i]
  if sum!=InputScale:return -1
  let full=(1'u64 shl n)-1;let pathAt=2+n
  for t in 0..<h:
    let mask=input[pathAt+t]
    if mask<=0 or (cast[uint64](mask) and not full)!=0:return -1
  var lcm=1'i64
  for t in 2'i64..h64:lcm=(lcm div gcd(lcm,t))*t
  let q=InputScale*lcm;let drawAt=pathAt+h
  for i in 0..<(n*h):if input[drawAt+i]<0 or input[drawAt+i]>=q:return -1
  var state:array[MaxN,int64]
  for i in 0..<n:state[i]=lambda[i]*lcm
  for t in 0..<h:
    let divisor=int64(t+1);let delta=q div divisor;let path=cast[uint64](input[pathAt+t])
    for i in 0..<n:
      if state[i]<0 or state[i]>q:return -1
      let r=if input[drawAt+t*n+i]<state[i]:1'i64 else:0'i64
      let x=int64((path shr i) and 1)
      let updated=state[i]+(x-r)*delta
      if updated<0 or updated>q:return -1
      state[i]=updated
  let bytes=8*(1+n)
  if output.isNil or capacity<csize_t(bytes):return -2
  var staged:array[72,uint8];put64(addr staged[0],0,q)
  for i in 0..<n:put64(addr staged[0],8*(i+1),state[i])
  for b in 0..<bytes:output[b]=staged[b]
  int64(bytes)
