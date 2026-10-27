const MaxVars=12;const MaxClauses=32;const MaxInput=98;const MaxOutput=96
proc putI64(output:ptr UncheckedArray[uint8],offset:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[offset+b]=uint8((bits shr (8*b)) and 255)
proc random_planted_3sat_majority_vote*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"random_planted_3sat_majority_vote".}=
  if input==nil or length<2 or length>MaxInput:return -1
  if input[0]<3 or input[0]>int64(MaxVars) or input[1]<0 or input[1]>int64(MaxClauses):return -1
  let n=int(input[0]);let m=int(input[1]);if int(length)!=2+3*m:return -1
  var positive,negative:array[MaxVars,int]
  for c in 0..<m:
    var seen:array[MaxVars,bool]
    for j in 0..<3:
      let lit=input[2+3*c+j];if lit==0 or lit < -int64(n) or lit>int64(n):return -1
      let v=int(abs(lit))-1;if seen[v]:return -1;seen[v]=true
      if lit>0:inc positive[v] else:inc negative[v]
  let bytes=8*n;if output==nil or int(capacity)<bytes:return -2
  var staged:array[MaxOutput,uint8]
  for v in 0..<n:putI64(addr staged[0],8*v,if positive[v]>negative[v]:1 else:-1)
  for i in 0..<bytes:output[i]=staged[i]
  int64(bytes)
