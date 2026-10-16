const MaxOps=128
const MaxLevels=8
const MinKey:int64 = -2147483647
const MaxKey:int64 = 2147483646
type Node=object
  key,value:int64
  level:int
  next:array[MaxLevels,int]

proc randomLevel(state:var uint32):int=
  result=1
  while result<MaxLevels:
    state=state xor (state shl 13);state=state xor (state shr 17);state=state xor (state shl 5)
    if (state and 1'u32)!=0:break
    inc result
proc findUpdate(nodes:var array[MaxOps+1,Node],active:int,key:int64,update:var array[MaxLevels,int]):int=
  var current=0
  for level in countdown(active-1,0):
    while nodes[current].next[level]!=0 and nodes[nodes[current].next[level]].key<key:current=nodes[current].next[level]
    update[level]=current
  nodes[current].next[0]
proc contains(nodes:var array[MaxOps+1,Node],active:int,key:int64):bool=
  var update:array[MaxLevels,int]
  let found=findUpdate(nodes,active,key,update)
  found!=0 and nodes[found].key==key
proc insert(nodes:var array[MaxOps+1,Node],next:var int,active:var int,rng:var uint32,key:int64)=
  var update:array[MaxLevels,int]
  discard findUpdate(nodes,active,key,update)
  let height=randomLevel(rng)
  if height>active:
    for level in active..<height:update[level]=0
    active=height
  let id=next;inc next
  nodes[id].key=key;nodes[id].value=key;nodes[id].level=height
  for level in 0..<height:
    nodes[id].next[level]=nodes[update[level]].next[level]
    nodes[update[level]].next[level]=id
proc erase(nodes:var array[MaxOps+1,Node],active:int,key:int64):bool=
  var update:array[MaxLevels,int]
  let found=findUpdate(nodes,active,key,update)
  if found==0 or nodes[found].key!=key:return false
  for level in 0..<active:
    if nodes[update[level]].next[level]==found:nodes[update[level]].next[level]=nodes[found].next[level]
  true
proc putI64(output:ptr UncheckedArray[uint8],offset:int,value:int64)=
  let bits=cast[uint64](value)
  for byte in 0..<8:output[offset+byte]=uint8((bits shr (8*byte)) and 255)

proc skip_list_unique_key_set*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"skip_list_unique_key_set".}=
  if input.isNil or length<1 or length>257 or input[0]<0 or input[0]>MaxOps or int(length)!=1+2*int(input[0]):return -1
  let ops=int(input[0])
  for i in 0..<ops:
    let op=input[1+2*i];let key=input[2+2*i]
    if op<0 or op>2 or key<MinKey or key>MaxKey:return -1
  var nodes:array[MaxOps+1,Node]
  var next=1;var active=1;var rng=0x9e3779b9'u32
  for i in 0..<ops:
    let op=input[1+2*i];let key=input[2+2*i]
    if op==0:
      if contains(nodes,active,key):return -1
      insert(nodes,next,active,rng,key)
    elif op==1:discard contains(nodes,active,key)
    elif not erase(nodes,active,key):return -1
  var count=0;var id=nodes[0].next[0]
  while id!=0:inc count;id=nodes[id].next[0]
  let required=count*8
  if output.isNil or int(capacity)<required:return -2
  id=nodes[0].next[0];var index=0
  while id!=0:putI64(output,index*8,nodes[id].value);inc index;id=nodes[id].next[0]
  int64(required)
