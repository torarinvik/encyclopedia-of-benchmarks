const MaxText=24
const MaxPattern=12
const MaxInput=39
const MaxNodes=51
type Node=object
  start,length,suffix,childCount:int
  children:array[MaxNodes,int]
proc codeAt(input:ptr UncheckedArray[int64],n,p:int):int64=
  if p==n:return -1
  input[1+p]
proc put64(output:ptr UncheckedArray[uint8],pos:int,value:int64)=
  let bits=cast[uint64](value)
  for j in 0..<8:output[pos+j]=uint8((bits shr (8*j)) and 255)
proc suffixLess(input:ptr UncheckedArray[int64],n,a,b:int):bool=
  var p=0
  while a+p<=n and b+p<=n:
    let x=codeAt(input,n,a+p);let y=codeAt(input,n,b+p)
    if x!=y:return x<y
    inc p
  a<b
proc suffix_tree_pattern_occurrences*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"suffix_tree_pattern_occurrences".}=
  if input.isNil or length<csize_t(3) or length>csize_t(MaxInput):return -1
  let nr=input[0];if nr<0 or nr>MaxText:return -1
  let n=int(nr);if int(length)<2+n:return -1
  let mr=input[1+n];if mr<1 or mr>MaxPattern or int(length)!=2+n+int(mr):return -1
  let m=int(mr)
  for i in 0..<n:if input[1+i]<0 or input[1+i]>127:return -1
  for i in 0..<m:if input[2+n+i]<0 or input[2+n+i]>127:return -1
  var nodes:array[MaxNodes,Node];var nodeCount=1
  for start in 0..n:
    let suffixLen=n+1-start
    var offset=0;var node=0
    while offset<suffixLen:
      let first=codeAt(input,n,start+offset)
      var slot=0
      while slot<nodes[node].childCount and codeAt(input,n,nodes[nodes[node].children[slot]].start)!=first:inc slot
      if slot==nodes[node].childCount:
        if nodeCount>=MaxNodes:return -1
        let leaf=nodeCount;inc nodeCount
        nodes[leaf].start=start+offset;nodes[leaf].length=suffixLen-offset;nodes[leaf].suffix=start
        nodes[node].children[nodes[node].childCount]=leaf;inc nodes[node].childCount
        break
      let child=nodes[node].children[slot];var common=0
      while common<nodes[child].length and offset+common<suffixLen and codeAt(input,n,start+offset+common)==codeAt(input,n,nodes[child].start+common):inc common
      if common==nodes[child].length:offset+=common;node=child;continue
      if nodeCount>=MaxNodes:return -1
      let split=nodeCount;inc nodeCount
      nodes[split].start=nodes[child].start;nodes[split].length=common
      nodes[split].children[0]=child;nodes[split].childCount=1
      nodes[child].start+=common;nodes[child].length-=common;nodes[node].children[slot]=split
      offset+=common;node=split
  var node=0;var offset=0;var matched=false
  while offset<m:
    let wanted=input[2+n+offset];var slot=0
    while slot<nodes[node].childCount and codeAt(input,n,nodes[nodes[node].children[slot]].start)!=wanted:inc slot
    if slot==nodes[node].childCount:break
    let child=nodes[node].children[slot];var common=0
    while common<nodes[child].length and offset+common<m and codeAt(input,n,nodes[child].start+common)==input[2+n+offset+common]:inc common
    if offset+common==m:node=child;matched=true;break
    if common!=nodes[child].length:break
    offset+=common;node=child
  var starts:array[MaxText,int];var count=0
  if matched:
    var stack:array[MaxNodes,int];var top=1;stack[0]=node
    while top>0:
      dec top;let x=stack[top]
      if nodes[x].childCount==0 and nodes[x].length>0:starts[count]=nodes[x].suffix;inc count
      for j in 0..<nodes[x].childCount:stack[top]=nodes[x].children[j];inc top
  for i in 1..<count:
    let x=starts[i];var j=i
    while j>0 and suffixLess(input,n,x,starts[j-1]):starts[j]=starts[j-1];dec j
    starts[j]=x
  let bytes=8*(1+count)
  if output.isNil or capacity<csize_t(bytes):return -2
  put64(output,0,int64(count));for i in 0..<count:put64(output,8+8*i,int64(starts[i]))
  int64(bytes)
