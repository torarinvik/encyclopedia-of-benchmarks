const MaxOps=128
const RootCount=9
const Empty = -1

type Node=object
  value:int64
  child,sibling,degree:int
type Heap=object
  nodes:array[MaxOps,Node]
  roots:array[RootCount,int]
  used,size:int
proc link(h:var Heap,a,b:int):int=
  var p,c:int
  if h.nodes[a].value<h.nodes[b].value:p=a;c=b
  else:p=b;c=a
  h.nodes[c].sibling=h.nodes[p].child;h.nodes[p].child=c;inc h.nodes[p].degree;p
proc add(h:var Heap,initial:int)=
  var r=initial;var d=h.nodes[r].degree
  while h.roots[d]!=Empty:r=link(h,r,h.roots[d]);h.roots[d]=Empty;inc d
  h.roots[d]=r
proc insert(h:var Heap,v:int64)=
  let r=h.used;inc h.used;h.nodes[r]=Node(value:v,child:Empty,sibling:Empty,degree:0);inc h.size;add(h,r)
proc minroot(h:Heap):int=
  result=Empty
  for r in h.roots:
    if r!=Empty and (result==Empty or h.nodes[r].value<h.nodes[result].value):result=r
proc extract(h:var Heap):int64=
  let b=minroot(h);let d=h.nodes[b].degree;result=h.nodes[b].value;h.roots[d]=Empty;var c=h.nodes[b].child
  while c!=Empty:let next=h.nodes[c].sibling;h.nodes[c].sibling=Empty;add(h,c);c=next
  dec h.size
proc put(out:ptr UncheckedArray[uint8],i:int,v:int64)=
  let bits=cast[uint64](v)
  for b in 0..<8:out[i*8+b]=uint8((bits shr (8*b)) and 255'u64)
proc binomial_heap*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"binomial_heap".}=
  if input.isNil or length<csize_t(1) or input[0]<0 or input[0]>MaxOps:return -1
  let n=int(input[0]);if int(length)!=1+2*n:return -1
  var q,size=0
  for i in 0..<n:
    let op=input[1+2*i];let v=input[2+2*i]
    if op==0:
      if v<int64(low(int32)) or v>int64(high(int32)):return -1
      inc size
    elif op>=1 and op<=3:
      if v!=0 or ((op==1 or op==2) and size==0):return -1
      if op==2:dec size
      inc q
    else:return -1
  let need=q*8
  if capacity<csize_t(need) or (need>0 and output.isNil):return -2
  var h:Heap
  for i in 0..<RootCount:h.roots[i]=Empty
  var w=0
  for i in 0..<n:
    let op=input[1+2*i];let v=input[2+2*i]
    var r:int64
    if op==0:insert(h,v);continue
    elif op==1:r=h.nodes[minroot(h)].value
    elif op==2:r=extract(h)
    else:
      if h.size==0:r=1'i64 else:r=0'i64
    put(output,w,r);inc w
  int64(w)
