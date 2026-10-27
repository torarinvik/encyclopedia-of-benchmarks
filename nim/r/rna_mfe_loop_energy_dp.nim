const MaxN=12
const MaxPairs=36
const TableValues=234
const MaxInput=247
const MaxOutput=112
const Inf=1'i64 shl 60

proc pairType(a,b:int64):int=
  if a==0 and b==3:return 0
  if a==3 and b==0:return 1
  if a==1 and b==2:return 2
  if a==2 and b==1:return 3
  if a==2 and b==3:return 4
  if a==3 and b==2:return 5
  -1

proc lexLessMask(left,right:uint64,count:int):bool=
  var li=0;var ri=0
  while true:
    while li<count and ((left shr li) and 1)==0:inc li
    while ri<count and ((right shr ri) and 1)==0:inc ri
    if li==count or ri==count:return li==count and ri<count
    if li!=ri:return li<ri
    inc li;inc ri

proc put64(outp:ptr UncheckedArray[uint8],at:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:outp[at+b]=uint8((bits shr (8*b)) and 255)

proc rna_mfe_loop_energy_dp*(input:ptr UncheckedArray[int64],length:csize_t,
    output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"rna_mfe_loop_energy_dp".}=
  if input.isNil or length<csize_t(239) or length>csize_t(MaxInput):return -1
  let n64=input[0]
  if n64<4 or n64>MaxN or int(length)!=1+int(n64)+TableValues:return -1
  let n=int(n64)
  var bases:array[MaxN,int64]
  for i in 0..<n:
    bases[i]=input[1+i]
    if bases[i]<0 or bases[i]>3:return -1
  for i in 1+n..<int(length):if input[i]< -1000 or input[i]>1000:return -1
  var types:array[MaxN,array[MaxN,int]]
  var ids:array[MaxN,array[MaxN,int]]
  for i in 0..<MaxN:
    for j in 0..<MaxN:types[i][j] = -1;ids[i][j] = -1
  var pairI:array[MaxPairs,int]
  var pairJ:array[MaxPairs,int]
  var pairCount=0
  for i in 0..<n:
    for j in i+4..<n:
      let kind=pairType(bases[i],bases[j])
      if kind>=0:
        types[i][j]=kind;ids[i][j]=pairCount;pairI[pairCount]=i;pairJ[pairCount]=j;inc pairCount
  var ve:array[MaxN,array[MaxN,int64]]
  var vm:array[MaxN,array[MaxN,uint64]]
  for i in 0..<MaxN:
    for j in 0..<MaxN:ve[i][j]=Inf
  template cost(kind,u,k:int):int64 = input[1+n+kind*39+u*3+k]
  for span in 4..<n:
    for i in 0..<n-span:
      let j=i+span
      let kind=types[i][j]
      if kind<0:continue
      let outer=1'u64 shl ids[i][j]
      var best=Inf
      var bestMask=0'u64
      var candidate=cost(kind,span-1,0)
      if candidate<best or (candidate==best and lexLessMask(outer,bestMask,pairCount)):
        best=candidate;bestMask=outer
      for a in i+1..<j:
        for b in a+4..<j:
          if ids[a][b]<0 or ve[a][b]==Inf:continue
          let unpaired=a-i-1+j-b-1
          candidate=cost(kind,unpaired,1)+ve[a][b]
          let mask=outer or vm[a][b]
          if candidate<best or (candidate==best and lexLessMask(mask,bestMask,pairCount)):
            best=candidate;bestMask=mask
      for a in i+1..<j:
        for b in a+4..<j:
          if ids[a][b]<0 or ve[a][b]==Inf:continue
          for c in b+1..<j:
            for d in c+4..<j:
              if ids[c][d]<0 or ve[c][d]==Inf:continue
              let unpaired=a-i-1+c-b-1+j-d-1
              candidate=cost(kind,unpaired,2)+ve[a][b]+ve[c][d]
              let mask=outer or vm[a][b] or vm[c][d]
              if candidate<best or (candidate==best and lexLessMask(mask,bestMask,pairCount)):
                best=candidate;bestMask=mask
      ve[i][j]=best;vm[i][j]=bestMask
  var we:array[MaxN,int64]
  var wm:array[MaxN,uint64]
  for j in 0..<n:
    var best=0'i64;var bestMask=0'u64
    if j>0:best=we[j-1];bestMask=wm[j-1]
    if j>=4:
      for i in 0..j-4:
        if types[i][j]<0 or ve[i][j]==Inf:continue
        var prefix=0'i64;var prefixMask=0'u64
        if i>0:prefix=we[i-1];prefixMask=wm[i-1]
        let value=prefix+ve[i][j]
        let mask=prefixMask or vm[i][j]
        if value<best or (value==best and lexLessMask(mask,bestMask,pairCount)):
          best=value;bestMask=mask
    we[j]=best;wm[j]=bestMask
  var count=0
  for p in 0..<pairCount:if ((wm[n-1] shr p) and 1)!=0:inc count
  let bytes=8*(2+2*count)
  if output.isNil or capacity<csize_t(bytes):return -2
  var staged:array[MaxOutput,uint8]
  put64(cast[ptr UncheckedArray[uint8]](addr staged[0]),0,we[n-1])
  put64(cast[ptr UncheckedArray[uint8]](addr staged[0]),8,int64(count))
  var at=2
  for p in 0..<pairCount:
    if ((wm[n-1] shr p) and 1)!=0:
      put64(cast[ptr UncheckedArray[uint8]](addr staged[0]),8*at,int64(pairI[p]));inc at
      put64(cast[ptr UncheckedArray[uint8]](addr staged[0]),8*at,int64(pairJ[p]));inc at
  for b in 0..<bytes:output[b]=staged[b]
  int64(bytes)
