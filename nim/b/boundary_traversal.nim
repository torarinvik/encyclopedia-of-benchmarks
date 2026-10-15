const MaxN=100
proc validate(nodes: ptr UncheckedArray[int64], n:csize_t, node:int64, seen:var array[MaxN,bool], reached:var int):bool =
  if node == -1: return true
  if node < 0 or uint64(node) >= uint64(n): return false
  let i=int(node)
  if seen[i]: return false
  seen[i]=true; inc reached
  let v=nodes[3*i]; let l=nodes[3*i+1]; let r=nodes[3*i+2]
  if v<int64(low(int32)) or v>int64(high(int32)) or l< -1 or r< -1 or (l>=0 and uint64(l)>=uint64(n)) or (r>=0 and uint64(r)>=uint64(n)): return false
  validate(nodes,n,l,seen,reached) and validate(nodes,n,r,seen,reached)
proc isLeaf(nodes:ptr UncheckedArray[int64],i:int):bool = nodes[3*i+1]== -1 and nodes[3*i+2]== -1
proc emitLeaves(nodes:ptr UncheckedArray[int64],node:int64,outp:ptr UncheckedArray[int64],used:var int) =
  if node == -1: return
  let i=int(node)
  if isLeaf(nodes,i): outp[used]=nodes[3*i];inc used;return
  emitLeaves(nodes,nodes[3*i+1],outp,used);emitLeaves(nodes,nodes[3*i+2],outp,used)
proc boundary_traversal*(nodes:ptr UncheckedArray[int64],n:csize_t,root:int64,outp:ptr UncheckedArray[int64],capacity:csize_t):int64 {.cdecl,exportc:"boundary_traversal".} =
  if n>MaxN or capacity<n:return -1
  if n==0:return (if root == -1: 0 else: -1)
  if nodes.isNil or outp.isNil or root<0 or uint64(root)>=uint64(n):return -1
  var seen:array[MaxN,bool];var reached=0
  if not validate(nodes,n,root,seen,reached) or reached!=int(n):return -1
  var used=0;let ri=int(root)
  if not isLeaf(nodes,ri):outp[used]=nodes[3*ri];inc used
  var cur=nodes[3*ri+1];if cur == -1 and nodes[3*ri+2] != -1:cur=nodes[3*ri+2]
  while cur != -1:
    let i=int(cur);if not isLeaf(nodes,i):outp[used]=nodes[3*i];inc used
    cur=if nodes[3*i+1] != -1:nodes[3*i+1] else:nodes[3*i+2]
  emitLeaves(nodes,root,outp,used)
  if nodes[3*ri+2] != -1 and nodes[3*ri+1] == -1:return int64(used)
  var right:array[MaxN,int64];var rn=0;cur=nodes[3*ri+2]
  while cur != -1:
    let i=int(cur);if not isLeaf(nodes,i):right[rn]=nodes[3*i];inc rn
    cur=if nodes[3*i+2] != -1:nodes[3*i+2] else:nodes[3*i+1]
  while rn>0:dec rn;outp[used]=right[rn];inc used
  int64(used)
