const MaxN = 8
const MaxK = 8
const MaxInput = 75

proc put64(output: ptr UncheckedArray[uint8], pos: int, value: int64) =
  let bits = cast[uint64](value)
  for j in 0 ..< 8: output[pos+j] = uint8((bits shr (8*j)) and 255)

proc radio_network_decay_phase*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"radio_network_decay_phase".} =
  if input.isNil or length < 3 or length > csize_t(MaxInput): return -1
  let n64=input[0]; let k64=input[1]; let initial=input[2]
  if n64<2 or n64>MaxN or k64<1 or k64>MaxK or int64(length)!=3+n64+n64*k64: return -1
  let n=int(n64); let k=int(k64); let full=(1'u64 shl n)-1
  if initial<=0 or (cast[uint64](initial) and not full)!=0: return -1
  var adjacency: array[MaxN,uint64]
  for v in 0..<n:
    let raw=input[3+v]
    if raw<0 or (cast[uint64](raw) and not full)!=0 or (cast[uint64](raw) and (1'u64 shl v))!=0: return -1
    adjacency[v]=cast[uint64](raw)
  for u in 0..<n:
    for v in 0..<n:
      if ((adjacency[u] shr v) and 1) != ((adjacency[v] shr u) and 1): return -1
  let tapeAt=3+n
  for i in 0..<(n*k):
    if input[tapeAt+i]!=0 and input[tapeAt+i]!=1: return -1
  if output.isNil or capacity<16: return -2
  var active: array[MaxN,bool]
  for v in 0..<n: active[v]=((cast[uint64](initial) shr v) and 1)!=0
  var newly=0'u64; var transmissions=0'i64
  for slot in 0..<k:
    for sender in 0..<n: if active[sender]: inc transmissions
    for receiver in 0..<n:
      if ((cast[uint64](initial) shr receiver) and 1)!=0: continue
      var count=0
      for sender in 0..<n:
        if active[sender] and ((adjacency[sender] shr receiver) and 1)!=0: inc count
      if count==1: newly=newly or (1'u64 shl receiver)
    for sender in 0..<n:
      if active[sender] and (input[tapeAt+sender*k+slot]==0 or slot+1==k): active[sender]=false
  var staged: array[16,uint8]
  put64(addr staged[0],0,cast[int64](newly)); put64(addr staged[0],8,transmissions)
  for b in 0..<16: output[b]=staged[b]
  16
