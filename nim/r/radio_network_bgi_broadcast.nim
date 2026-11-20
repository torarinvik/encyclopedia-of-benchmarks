const MaxN = 8
const MaxInput = 203
const MaxOutput = 88

proc ceilLog2(value: int): int =
  var power = 1
  while power < value:
    power = power shl 1
    inc result

proc put64(output: ptr UncheckedArray[uint8], pos: int, value: int64) =
  let bits = cast[uint64](value)
  for j in 0 ..< 8: output[pos+j] = uint8((bits shr (8*j)) and 255)

proc radio_network_bgi_broadcast*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"radio_network_bgi_broadcast".} =
  if input.isNil or length < 3 or length > csize_t(MaxInput): return -1
  let n64=input[0]; let source64=input[1]; let delta64=input[2]
  if n64<2 or n64>MaxN or source64<0 or source64>=n64 or delta64<2 or delta64>8: return -1
  let n=int(n64); let source=int(source64); let delta=int(delta64)
  let k=2*ceilLog2(delta); let t=ceilLog2(2*n); let tapeAt=3+n; let tapeCount=n*t*k
  if int64(length)!=int64(tapeAt+tapeCount): return -1
  let full=(1'u64 shl n)-1
  var adjacency: array[MaxN,uint64]
  for v in 0..<n:
    let raw=input[3+v]
    if raw<0 or (cast[uint64](raw) and not full)!=0 or (cast[uint64](raw) and (1'u64 shl v))!=0: return -1
    adjacency[v]=cast[uint64](raw)
    var degree=0
    for u in 0..<n:
      if ((adjacency[v] shr u) and 1)!=0: inc degree
    if degree>delta: return -1
  for u in 0..<n:
    for v in 0..<n:
      if ((adjacency[u] shr v) and 1)!=((adjacency[v] shr u) and 1): return -1
  for i in 0..<tapeCount:
    if input[tapeAt+i]!=0 and input[tapeAt+i]!=1: return -1
  let outputBytes=8*(n+3)
  if output.isNil or capacity<csize_t(outputBytes): return -2

  var informed, active, newly: array[MaxN,bool]
  var calls: array[MaxN,int]
  var firstSlot: array[MaxN,int64]
  for v in 0..<n: firstSlot[v] = -1
  informed[source]=true; firstSlot[source]=0
  var transmissions=0'i64; var phases=0'i64
  for phase in 0..<(n*t):
    var starters=0
    for v in 0..<n:
      active[v]=informed[v] and calls[v]<t
      newly[v]=false
      if active[v]: inc starters
    if starters==0: break
    for slot in 0..<k:
      for sender in 0..<n: if active[sender]: inc transmissions
      for receiver in 0..<n:
        if informed[receiver] or newly[receiver]: continue
        var senderCount=0
        for sender in 0..<n:
          if active[sender] and ((adjacency[sender] shr receiver) and 1)!=0: inc senderCount
        if senderCount==1:
          newly[receiver]=true
          firstSlot[receiver]=int64(phase*k+slot)
      for sender in 0..<n:
        if active[sender]:
          let at=tapeAt+(sender*t+calls[sender])*k+slot
          if slot+1==k or input[at]==0: active[sender]=false
    for v in 0..<n:
      if informed[v] and calls[v]<t: inc calls[v]
      if newly[v]: informed[v]=true
    phases=int64(phase+1)
  var staged: array[MaxOutput,uint8]
  put64(addr staged[0],0,n64); put64(addr staged[0],8,phases); put64(addr staged[0],16,transmissions)
  for v in 0..<n: put64(addr staged[0],24+8*v,firstSlot[v])
  for b in 0..<outputBytes: output[b]=staged[b]
  int64(outputBytes)
