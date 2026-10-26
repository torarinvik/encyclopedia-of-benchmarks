## Subset/endpoint dynamic program for a colorful path of exactly k vertices.
proc color_coding_k_path*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "color_coding_k_path".} =
  if values == nil: return -2
  if length < 3 or length > 147: return -1
  let nv=values[0];let mv=values[1];let kv=values[2]
  if nv<1 or nv>12 or mv<0 or mv>66 or kv<1 or kv>6 or kv>nv:return -1
  let n=int(nv);let m=int(mv);let k=int(kv);let split=3+n
  if int(length)!=split+2*m:return -1
  var colors:array[12,int];var adj:array[12,uint16]
  for v in 0..<n:
    if values[3+v]<0 or values[3+v]>=kv:return -1
    colors[v]=int(values[3+v])
  for e in 0..<m:
    let av=values[split+2*e];let bv=values[split+2*e+1]
    if av<0 or bv<0 or av>=nv or bv>=nv or av==bv:return -1
    let a=int(av);let b=int(bv);let bit=uint16(1 shl b)
    if (adj[a] and bit)!=0:return -1
    adj[a]=adj[a] or bit;adj[b]=adj[b] or uint16(1 shl a)
  var dp:array[64,array[12,bool]]
  for v in 0..<n:dp[1 shl colors[v]][v]=true
  let full=(1 shl k)-1;var found=false
  for mask in 1..full:
    for v in 0..<n:
      if not dp[mask][v]:continue
      if mask==full:found=true;break
      for u in 0..<n:
        let bit=1 shl colors[u]
        if (adj[v] and uint16(1 shl u))!=0 and (mask and bit)==0:dp[mask or bit][u]=true
    if found:break
  if outputCapacity<8 or output==nil:return -2
  if found: output[0]=1'u8 else: output[0]=0'u8
  for i in 1..<8:output[i]=0
  return 8
