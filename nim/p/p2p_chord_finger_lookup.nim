const MaxNodes=16;const MaxBits=6;const MaxInput=116;const MaxOutput=128
proc putI64(output:ptr UncheckedArray[uint8],offset:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[offset+b]=uint8((bits shr (8*b)) and 255)
proc p2p_chord_finger_lookup*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"p2p_chord_finger_lookup".}=
  if input==nil or length<4 or length>MaxInput:return -1
  if input[0]<1 or input[0]>int64(MaxBits) or input[1]<2 or input[1]>int64(MaxNodes):return -1
  let bits=int(input[0]);let n=int(input[1]);if n>(1 shl bits) or input[2]<0 or input[2]>=int64(n) or input[3]<0 or input[3]>=int64(1 shl bits):return -1
  let start=int(input[2]);let ring=1 shl bits;if int(length)!=4+n+n*bits:return -1
  var ids:array[MaxNodes,int];var fingers:array[MaxNodes*MaxBits,int]
  for i in 0..<n:
    let raw=input[4+i];if raw<0 or raw>=ring or (i>0 and raw<=ids[i-1]):return -1
    ids[i]=int(raw)
  for node in 0..<n:
    for level in 0..<bits:
      var successor=0;let target=(ids[node]+(1 shl level)) mod ring
      while successor<n and ids[successor]<target:inc successor
      if successor==n:successor=0
      let pointer=input[4+n+node*bits+level];if pointer!=int64(successor):return -1
      fingers[node*bits+level]=successor
  let key=int(input[3]);var owner=0;while owner<n and ids[owner]<key:inc owner
  if owner==n:owner=0
  var route:array[MaxNodes,int];var routeLen=1;var current=start;route[0]=current
  for step in 0..<n:
    if current==owner:break
    let targetDistance=(ids[owner]-ids[current]+ring) mod ring
    var chosen = -1
    for level in countdown(bits-1,0):
      let candidate=fingers[current*bits+level];let progress=(ids[candidate]-ids[current]+ring) mod ring
      if progress>0 and progress<=targetDistance:chosen=candidate;break
    if chosen<0 or routeLen>=n:return -1
    for j in 0..<routeLen:if route[j]==chosen:return -1
    current=chosen;route[routeLen]=current;inc routeLen
  if current!=owner:return -1
  let bytes=8*routeLen;if output==nil or int(capacity)<bytes:return -2
  var staged:array[MaxOutput,uint8]
  for i in 0..<routeLen:putI64(addr staged[0],8*i,int64(ids[route[i]]))
  for i in 0..<bytes:output[i]=staged[i]
  int64(bytes)
