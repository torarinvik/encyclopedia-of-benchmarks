const MaxNodes = 64
const MaxOps = 128
type AvlNode = object
  key: int64
  left, right, height: int

proc nodeHeight(nodes: array[MaxNodes, AvlNode], i: int): int = if i < 0: 0 else: nodes[i].height
proc updateHeight(nodes: var array[MaxNodes, AvlNode], i: int) = nodes[i].height = 1 + max(nodeHeight(nodes,nodes[i].left), nodeHeight(nodes,nodes[i].right))
proc rotateRight(nodes: var array[MaxNodes, AvlNode], root: int): int =
  let pivot=nodes[root].left;let middle=nodes[pivot].right;nodes[pivot].right=root;nodes[root].left=middle;updateHeight(nodes,root);updateHeight(nodes,pivot);pivot
proc rotateLeft(nodes: var array[MaxNodes, AvlNode], root: int): int =
  let pivot=nodes[root].right;let middle=nodes[pivot].left;nodes[pivot].left=root;nodes[root].right=middle;updateHeight(nodes,root);updateHeight(nodes,pivot);pivot
proc insertNode(nodes: var array[MaxNodes, AvlNode], root: int, key: int64, next: var int): int =
  if root < 0:
    result=next;inc next;nodes[result]=AvlNode(key:key,left:-1,right:-1,height:1);return
  if key<nodes[root].key: nodes[root].left=insertNode(nodes,nodes[root].left,key,next)
  else: nodes[root].right=insertNode(nodes,nodes[root].right,key,next)
  updateHeight(nodes,root)
  let balance=nodeHeight(nodes,nodes[root].left)-nodeHeight(nodes,nodes[root].right)
  if balance>1:
    if key>nodes[nodes[root].left].key:nodes[root].left=rotateLeft(nodes,nodes[root].left)
    return rotateRight(nodes,root)
  if balance < -1:
    if key<nodes[nodes[root].right].key:nodes[root].right=rotateRight(nodes,nodes[root].right)
    return rotateLeft(nodes,root)
  root
proc containsKey(nodes: array[MaxNodes, AvlNode], rootValue: int, key: int64): bool =
  var root=rootValue
  while root>=0:
    if nodes[root].key==key:return true
    root=if key<nodes[root].key:nodes[root].left else:nodes[root].right
  false
proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits=cast[uint64](value)
  for b in 0..<8:output[offset+b]=uint8((bits shr (b*8)) and 255'u64)

proc avl_tree_ruby_unique_key_insert_search*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "avl_tree_ruby_unique_key_insert_search".} =
  if input.isNil or length<1:return -1
  let opCount64=input[0];if opCount64<0 or opCount64>MaxOps or length!=csize_t(1+2*opCount64):return -1
  let opCount=int(opCount64);var inserted:array[MaxNodes,int64];var insertCount=0;var searchCount=0
  for i in 0..<opCount:
    let op=input[1+2*i];let key=input[2+2*i]
    if (op!=0 and op!=1) or key < -1_000_000 or key > 1_000_000:return -1
    if op==0:
      if insertCount>=MaxNodes:return -1
      for j in 0..<insertCount:if inserted[j]==key:return -1
      inserted[insertCount]=key;inc insertCount
    else:inc searchCount
  var nodes:array[MaxNodes,AvlNode];for i in 0..<MaxNodes:nodes[i].left = -1;nodes[i].right = -1
  var root = -1;var next=0;var results:array[MaxOps,int64];var q=0
  for i in 0..<opCount:
    let op=input[1+2*i];let key=input[2+2*i]
    if op==0:root=insertNode(nodes,root,key,next)
    else:results[q]=(if containsKey(nodes,root,key): 1'i64 else: 0'i64);inc q
  let bytes=(2+insertCount+searchCount)*8
  if output.isNil or capacity<csize_t(bytes):return -2
  putI64(output,0,int64(insertCount));var stack:array[MaxNodes,int];var top=0;var current=root;var out=1
  while current>=0 or top>0:
    while current>=0:stack[top]=current;inc top;current=nodes[current].left
    dec top;current=stack[top];putI64(output,out*8,nodes[current].key);inc out;current=nodes[current].right
  putI64(output,out*8,int64(searchCount));inc out
  for i in 0..<searchCount:putI64(output,out*8,results[i]);inc out
  int64(bytes)
