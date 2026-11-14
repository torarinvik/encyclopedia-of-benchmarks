## Independent suffix-array/LCP draft; compilation and output are unverified.
import std/algorithm

type
  Word = object
    start, length: int
  SuffixLcp = object
    rank, logs: seq[int]
    table: seq[seq[int]]

proc makeLcp(text: seq[int]): SuffixLcp =
  let n=text.len
  var suffixes=newSeq[int](n)
  var classes=newSeq[int](n)
  for i in 0 ..< n: classes[i]=text[i]
  var next=newSeq[int](n)
  for i in 0 ..< n: suffixes[i]=i
  var step=1
  while step<n:
    suffixes.sort(proc(a,b: int): int =
      let first=cmp(classes[a],classes[b])
      if first!=0: return first
      let aSecond=if a+step<n: classes[a+step] else: -1
      let bSecond=if b+step<n: classes[b+step] else: -1
      cmp(aSecond,bSecond)
    )
    next[suffixes[0]]=0
    for i in 1 ..< n:
      let a=suffixes[i-1]; let b=suffixes[i]
      let aSecond=if a+step<n: classes[a+step] else: -1
      let bSecond=if b+step<n: classes[b+step] else: -1
      next[b]=next[a]+int(classes[a]!=classes[b] or aSecond!=bSecond)
    swap(classes,next)
    if classes[suffixes[n-1]]==n-1: break
    step*=2
  result.rank=newSeq[int](n)
  for i in 0 ..< n: result.rank[suffixes[i]]=i
  var lcp=newSeq[int](n)
  var shared=0
  for i in 0 ..< n:
    let r=result.rank[i]
    if r==0:
      shared=0
      continue
    let j=suffixes[r-1]
    while i+shared<n and j+shared<n and text[i+shared]==text[j+shared]: inc shared
    lcp[r]=shared
    if shared>0: dec shared
  result.logs=newSeq[int](n+1)
  for i in 2 .. n: result.logs[i]=result.logs[i div 2]+1
  result.table.add(lcp)
  var width=2
  while width<=n:
    let previous=result.table[^1]
    var row=newSeq[int](n-width+1)
    for i in 0 ..< row.len: row[i]=min(previous[i],previous[i+width div 2])
    result.table.add(row)
    width*=2

proc common(lcp: SuffixLcp, a,b,limit: int): int =
  if a==b: return limit
  let low=min(lcp.rank[a],lcp.rank[b])+1
  let high=max(lcp.rank[a],lcp.rank[b])
  let level=lcp.logs[high-low+1]
  min(limit,min(lcp.table[level][low],lcp.table[level][high-(1 shl level)+1]))

proc compareWords(a,b: int, words: seq[Word], text: seq[int], lcp: SuffixLcp): int =
  let left=[words[a],words[b]]; let right=[words[b],words[a]]
  var li=0; var ri=0; var lp=0; var rp=0
  while li<2 and ri<2:
    let limit=min(left[li].length-lp,right[ri].length-rp)
    let same=lcp.common(left[li].start+lp,right[ri].start+rp,limit)
    if same<limit: return cmp(text[left[li].start+lp+same],text[right[ri].start+rp+same])
    lp+=same; rp+=same
    if lp==left[li].length: inc li; lp=0
    if rp==right[ri].length: inc ri; rp=0
  cmp(a,b)

proc lexicographically_minimal_concatenation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "lexicographically_minimal_concatenation".} =
  if input.isNil or length==0 or input[0]<0 or input[0]>16384: return -1
  let n=int(input[0])
  var words: seq[Word] = @[]
  var text: seq[int] = @[]
  var offset=1; var total=0
  for i in 0 ..< n:
    if offset>=int(length) or input[offset]<1 or input[offset]>65536: return -1
    let size=int(input[offset]); inc offset
    if size>65536-total or size>int(length)-offset: return -1
    words.add(Word(start:text.len,length:size))
    for j in 0 ..< size:
      let value=input[offset+j]
      if value<97 or value>122: return -1
      text.add(int(value))
    offset+=size; total+=size
    text.add(0)
  if offset!=int(length): return -1
  if output.isNil or capacity<csize_t(total): return -2
  if n==0: return 0
  let lcp=makeLcp(text)
  var order=newSeq[int](n)
  for i in 0 ..< n: order[i]=i
  order.sort(proc(a,b: int): int = compareWords(a,b,words,text,lcp))
  var written=0
  for index in order:
    let word=words[index]
    for j in 0 ..< word.length:
      output[written]=uint8(text[word.start+j])
      inc written
  int64(written)
