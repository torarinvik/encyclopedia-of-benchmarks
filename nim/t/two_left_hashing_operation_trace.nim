proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset+b] = uint8((bits shr (8*b)) and 255'u64)

proc two_left_hashing_operation_trace*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "two_left_hashing_operation_trace".} =
  if input == nil or length < 5 or length > 162: return -1
  if input[0] < 1 or input[0] > 40 or int(length) != 1 + 4*int(input[0]): return -1
  let q=int(input[0])
  for i in 0 ..< q:
    let op=input[1+4*i];let key=input[2+4*i];let left=input[3+4*i];let right=input[4+4*i]
    if op < 0 or op > 2 or key < 0 or key > 63 or left < 0 or left > 7 or right < 0 or right > 7: return -1
    for j in 0 ..< i:
      if input[2+4*j] == key and (input[3+4*j] != left or input[4+4*j] != right): return -1
  let bytes=16*q
  if output == nil or capacity < csize_t(bytes): return -2
  var head: array[16,int];var sizes: array[16,int];var keys: array[32,int64];var next: array[32,int]
  var statuses: array[40,int64];var places: array[40,int64]
  for b in 0 ..< 16: head[b]= -1
  for x in 0 ..< 32: keys[x]= -1;next[x]= -1
  var live=0
  for i in 0 ..< q:
    let op=int(input[1+4*i]);let key=input[2+4*i];let lb=int(input[3+4*i]);let rb=8+int(input[4+4*i])
    var found= -1;var fb=0
    for bucket in [lb,rb]:
      var x=head[bucket]
      while x >= 0:
        if keys[x] == key: found=x;fb=bucket;break
        x=next[x]
      if found >= 0: break
    if op == 0:
      if found >= 0: statuses[i]=0;places[i]= -1;continue
      if live == 32: return -3
      let useLeft=sizes[lb] <= sizes[rb];let bucket=if useLeft: lb else: rb
      var node=0;while keys[node] >= 0: node += 1
      keys[node]=key;next[node]=head[bucket];head[bucket]=node;sizes[bucket]+=1;live+=1
      statuses[i]=1;places[i]=if useLeft: 0 else: 1
    elif op == 1: statuses[i]=if found >= 0: 1 else: 0;places[i]= -1
    elif found < 0: statuses[i]=0;places[i]= -1
    else:
      var prev= -1;var x=head[fb]
      while x != found: prev=x;x=next[x]
      if prev < 0: head[fb]=next[x] else: next[prev]=next[x]
      keys[x]= -1;next[x]= -1;sizes[fb]-=1;live-=1;statuses[i]=1;places[i]= -1
  for i in 0 ..< q: storeLe(output,16*i,statuses[i]);storeLe(output,16*i+8,places[i])
  int64(bytes)
