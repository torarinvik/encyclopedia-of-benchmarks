const MaxWords=32
const MaxLen=16
const MaxQueries=16
const MaxNodes=513
const MaxOutputWords=8721
type TrieNode=object
  child:array[26,int]
  terminal:bool
proc initNode(node:var TrieNode)=
  for c in 0..<26:node.child[c]= -1
  node.terminal=false
proc collect(nodes:var array[MaxNodes,TrieNode],at:int,path:var array[MaxLen,int],depth:int,output:var array[MaxOutputWords,int64],used:var int,count:var int)=
  if nodes[at].terminal:
    output[used]=int64(depth);inc used
    for j in 0..<depth:output[used]=int64(ord('a')+path[j]);inc used
    inc count
  for c in 0..<26:
    let child=nodes[at].child[c]
    if child>=0:
      path[depth]=c
      collect(nodes,child,path,depth+1,output,used,count)
proc putI64(output:ptr UncheckedArray[uint8],index:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[index*8+b]=uint8((bits shr (8*b)) and 255)
proc autocomplete_using_trie*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"autocomplete_using_trie".}=
  if input.isNil or length<2 or input[0]<0 or input[0]>MaxWords:return -1
  var nodes:array[MaxNodes,TrieNode]
  initNode(nodes[0]);var nc=1;var pos=1
  for w in 0..<int(input[0]):
    if pos>=int(length):return -1
    let lv=input[pos];inc pos
    if lv<1 or lv>MaxLen or pos+int(lv)>int(length):return -1
    var at=0
    for _ in 0..<int(lv):
      let ch=input[pos];inc pos
      if ch<97 or ch>122:return -1
      let c=int(ch-97)
      if nodes[at].child[c]<0:
        if nc>=MaxNodes:return -1
        initNode(nodes[nc]);nodes[at].child[c]=nc;inc nc
      at=nodes[at].child[c]
    nodes[at].terminal=true
  if pos>=int(length):return -1
  let qv=input[pos];inc pos
  if qv<0 or qv>MaxQueries:return -1
  let q=int(qv);var qp,ql:array[MaxQueries,int]
  for i in 0..<q:
    if pos>=int(length):return -1
    let lv=input[pos];inc pos
    if lv<0 or lv>MaxLen or pos+int(lv)>int(length):return -1
    qp[i]=pos;ql[i]=int(lv)
    for j in 0..<ql[i]:
      if input[pos+j]<97 or input[pos+j]>122:return -1
    pos+=ql[i]
  if pos!=int(length):return -1
  var values:array[MaxOutputWords,int64];var used=0;values[used]=int64(q);inc used
  for i in 0..<q:
    var at=0;var path:array[MaxLen,int];var found=true
    for j in 0..<ql[i]:
      let c=int(input[qp[i]+j]-97);path[j]=c
      if nodes[at].child[c]<0:found=false;break
      at=nodes[at].child[c]
    let cp=used;inc used;var count=0
    if found:collect(nodes,at,path,ql[i],values,used,count)
    values[cp]=int64(count)
  let required=used*8
  if output.isNil or int(capacity)<required:return -2
  for i in 0..<used:putI64(output,i,values[i])
  int64(required)
