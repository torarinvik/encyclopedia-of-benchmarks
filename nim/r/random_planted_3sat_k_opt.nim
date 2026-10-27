const MaxVars=12;const MaxClauses=32;const MaxInput=98;const MaxOutput=104
proc putI64(output:ptr UncheckedArray[uint8],offset:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[offset+b]=uint8((bits shr (8*b)) and 255)
proc satSet(clauses:array[96,int],m,n:int,code:uint32):uint32=
  var result=0'u32
  for c in 0..<m:
    var satisfied=false
    for j in 0..<3:
      let lit=clauses[3*c+j];let v=abs(lit)-1;let truth=((code shr (n-1-v)) and 1'u32)!=0
      if truth==(lit>0):satisfied=true
    if satisfied:result=result or (1'u32 shl c)
  result
proc random_planted_3sat_k_opt*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"random_planted_3sat_k_opt".}=
  if input==nil or length<2 or length>MaxInput:return -1
  if input[0]<3 or input[0]>int64(MaxVars) or input[1]<0 or input[1]>int64(MaxClauses):return -1
  let n=int(input[0]);let m=int(input[1]);if int(length)!=2+3*m:return -1
  var clauses:array[96,int];var positive,negative:array[MaxVars,int]
  for c in 0..<m:
    var seen:array[MaxVars,bool]
    for j in 0..<3:
      let raw=input[2+3*c+j];if raw==0 or raw < -int64(n) or raw>int64(n):return -1
      let lit=int(raw);let v=abs(lit)-1;if seen[v]:return -1;seen[v]=true;clauses[3*c+j]=lit
      if lit>0:inc positive[v] else:inc negative[v]
  var current=0'u32
  for v in 0..<n:if positive[v]>negative[v]:current=current or (1'u32 shl (n-1-v))
  let full=if m==32:0xffff_ffff'u32 elif m==0:0'u32 else:(1'u32 shl m)-1
  var k=1;var status=0'i64
  while true:
    let before=satSet(clauses,m,n,current)
    if before==full:status=1;break
    var found=false
    for candidate in 0'u32..<(1'u32 shl n):
      var diff=current xor candidate;var distance=0
      while diff!=0:diff=diff and (diff-1);inc distance
      if distance==0 or distance>k:continue
      let after=satSet(clauses,m,n,candidate)
      if after!=before and (after and before)==before:current=candidate;found=true;break
    if found:continue
    if k==n:status=0;break
    inc k
  let bytes=8*(n+1);if output==nil or int(capacity)<bytes:return -2
  var staged:array[MaxOutput,uint8];putI64(addr staged[0],0,status)
  for v in 0..<n:putI64(addr staged[0],8*(v+1),if ((current shr (n-1-v)) and 1'u32)!=0:1 else:-1)
  for i in 0..<bytes:output[i]=staged[i]
  int64(bytes)
