const MaxLen = 32
const MaxBlocks = 16
const MaxWords = 114
const MaxBytes = 912
const MaxInput = 68

proc blockHash(data: array[MaxLen, int64], start, width: int): int64 =
  var value = 0'i64
  for i in 0 ..< width: value = value * 257 + data[start+i] + 1
  value

proc suffixCmp(h: array[MaxBlocks, int64], count, a0, b0: int): int =
  var a = a0
  var b = b0
  while a < count and b < count:
    if h[a] != h[b]: return (if h[a] < h[b]: -1 else: 1)
    inc a; inc b
  if a == count and b == count: 0 elif a == count: -1 else: 1

proc prefixCmp(h: array[MaxBlocks, int64], count: int, suffix: int,
               query: array[MaxBlocks, int64], depth: int): int =
  for i in 0 ..< depth:
    if suffix + i >= count: return -1
    if h[suffix+i] != query[i]: return (if h[suffix+i] < query[i]: -1 else: 1)
  0

proc prefixInterval(sa: array[MaxBlocks, int], count: int, h: array[MaxBlocks, int64],
                    query: array[MaxBlocks, int64], depth: int): tuple[first,last: int] =
  var lo = 0
  var hi = count
  while lo < hi:
    let mid = lo + (hi-lo) div 2
    if prefixCmp(h,count,sa[mid],query,depth) < 0: lo = mid+1 else: hi = mid
  let first = lo
  hi = count
  while lo < hi:
    let mid = lo + (hi-lo) div 2
    if prefixCmp(h,count,sa[mid],query,depth) <= 0: lo = mid+1 else: hi = mid
  (first,lo)

proc bestDepth(sa: array[MaxBlocks, int], count: int, h: array[MaxBlocks, int64],
               query: array[MaxBlocks, int64], qcount: int): int =
  var lo = 0
  var hi = min(count,qcount)+1
  while lo+1 < hi:
    let mid = lo+(hi-lo) div 2
    let bounds = prefixInterval(sa,count,h,query,mid)
    if bounds.first < bounds.last: lo=mid else: hi=mid
  lo

proc extendMatch(refData, verData: array[MaxLen, int64], m,n, source0,target0,floor: int): tuple[source,target,length: int] =
  var source=source0
  var target=target0
  var length=0
  while source+length<m and target+length<n and refData[source+length]==verData[target+length]: inc length
  while source>0 and target>floor and refData[source-1]==verData[target-1]:
    dec source; dec target; inc length
  (source,target,length)

proc better(a,b: tuple[source,target,length:int]): bool =
  a.length>b.length or (a.length==b.length and (a.target<b.target or (a.target==b.target and a.source<b.source)))

proc storeI64(outData: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: outData[offset+b]=uint8((bits shr (8*b)) and 255)

proc hsadelta_differential_compression*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "hsadelta_differential_compression".} =
  if input == nil or length < 3 or length > csize_t(MaxInput): return -1
  let mv=input[0]; let nv=input[1]; let pv=input[2]
  if mv<0 or mv>int64(MaxLen) or nv<0 or nv>int64(MaxLen) or pv<2 or pv>4: return -1
  let m=int(mv); let n=int(nv); let p=int(pv)
  if int(length)!=3+m+n: return -1
  var refData: array[MaxLen, int64]
  var verData: array[MaxLen, int64]
  for i in 0 ..< m+n:
    if input[3+i]<0 or input[3+i]>255: return -1
  for i in 0 ..< m: refData[i]=input[3+i]
  for i in 0 ..< n: verData[i]=input[3+m+i]

  var hashes: array[MaxBlocks,int64]
  var sa: array[MaxBlocks,int]
  let count=if m>=p: (m-p) div p+1 else: 0
  for i in 0 ..< count: hashes[i]=blockHash(refData,i*p,p); sa[i]=i
  if count > 1:
    for i in 1 ..< count:
      let value=sa[i]
      var j=i
      while j>0 and (suffixCmp(hashes,count,value,sa[j-1])<0 or (suffixCmp(hashes,count,value,sa[j-1])==0 and value<sa[j-1])):
        sa[j]=sa[j-1]; dec j
      sa[j]=value

  var tokens: array[MaxWords,int64]
  var words=0
  var cursor=0
  var consumed=0
  while cursor+p<=n:
    var found=false
    var best=(source:0,target:0,length:0)
    let scanEnd=min(cursor+p-1,n-p)
    for target in cursor .. scanEnd:
      let qcount=(n-target) div p
      if qcount==0 or count==0: continue
      var query: array[MaxBlocks,int64]
      for i in 0 ..< qcount: query[i]=blockHash(verData,target+i*p,p)
      let depth=bestDepth(sa,count,hashes,query,qcount)
      if depth==0: continue
      let bounds=prefixInterval(sa,count,hashes,query,max(1,depth-1))
      for rank in bounds.first ..< bounds.last:
        let source=sa[rank]*p
        if source+p>m: continue
        let candidate=extendMatch(refData,verData,m,n,source,target,consumed)
        if candidate.length<p: continue
        if not found or better(candidate,best): found=true; best=candidate
    if not found: inc cursor; continue
    if best.target>consumed:
      tokens[words]=0; inc words
      tokens[words]=int64(best.target-consumed); inc words
      for i in consumed ..< best.target: tokens[words]=verData[i]; inc words
    tokens[words]=1; inc words
    tokens[words]=int64(best.source); inc words
    tokens[words]=int64(best.length); inc words
    consumed=best.target+best.length
    cursor=consumed
  if consumed<n:
    tokens[words]=0; inc words
    tokens[words]=int64(n-consumed); inc words
    for i in consumed ..< n: tokens[words]=verData[i]; inc words
  let required=words*8
  if required>0 and (output==nil or int(capacity)<required): return -2
  for i in 0 ..< words: storeI64(output,8*i,tokens[i])
  int64(required)
