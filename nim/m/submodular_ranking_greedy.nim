const MaxN = 5
const MaxM = 4
const MaxInput = 131

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[offset+b] = uint8((bits shr (8*b)) and 255)

proc submodular_ranking_greedy*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "submodular_ranking_greedy".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let n64=input[0]; let m64=input[1]
  if n64<1 or n64>MaxN or m64<1 or m64>MaxM: return -1
  let n=int(n64);let m=int(m64);let size=1 shl n
  if int(length)!=2+m*size:return -1
  var f: array[MaxM,array[32,int64]]
  for i in 0..<m:
    for a in 0..<size:
      let v=input[2+i*size+a]
      if v<0 or v>8:return -1
      f[i][a]=v
    if f[i][0]!=0 or f[i][size-1]!=8:return -1
    for a in 0..<size:
      for bit in 0..<n:
        let e=1 shl bit
        if (a and e)==0 and f[i][a]>f[i][a or e]:return -1
    for a in 0..<size:
      for b in 0..<size:
        if (a and b)!=a:continue
        for bit in 0..<n:
          let e=1 shl bit
          if (b and e)==0 and f[i][a or e]-f[i][a]<f[i][b or e]-f[i][b]:return -1
  let outBytes=8*(1+n+m)
  if output.isNil or capacity<csize_t(outBytes):return -2
  var order: array[MaxN,int]
  var times: array[MaxM,int64]
  var total=0'i64
  var mask=0
  for t in 1..n:
    var winner=0
    var bestNum = -1'i64
    var bestDen = 1'i64
    for e in 0..<n:
      let bit=1 shl e
      if (mask and bit)!=0:continue
      var num=0'i64;var den=1'i64
      for i in 0..<m:
        let cur=f[i][mask]
        if cur==8:continue
        let d=8-cur;let gain=f[i][mask or bit]-cur
        num=num*d+gain*den;den=den*d
      if bestNum<0 or num*bestDen>bestNum*den:
        winner=e;bestNum=num;bestDen=den
    mask=mask or (1 shl winner);order[t-1]=winner
    for i in 0..<m:
      if times[i]==0 and f[i][mask]==8:
        times[i]=int64(t);total+=int64(t)
  storeI64LE(output,0,total)
  for j in 0..<n:storeI64LE(output,8*(1+j),int64(order[j]))
  for i in 0..<m:storeI64LE(output,8*(1+n+i),times[i])
  int64(outBytes)
