const MaxOps = 128
type Node = object
  key: int64
  left, right, parent: int
  red: bool
proc leftRotate(t: var array[MaxOps+1,Node], root: var int, x: int) =
  let y=t[x].right; t[x].right=t[y].left
  if t[y].left!=0: t[t[y].left].parent=x
  t[y].parent=t[x].parent
  if t[x].parent==0: root=y
  elif x==t[t[x].parent].left: t[t[x].parent].left=y
  else: t[t[x].parent].right=y
  t[y].left=x; t[x].parent=y
proc rightRotate(t: var array[MaxOps+1,Node], root: var int, y: int) =
  let x=t[y].left; t[y].left=t[x].right
  if t[x].right!=0: t[t[x].right].parent=y
  t[x].parent=t[y].parent
  if t[y].parent==0: root=x
  elif y==t[t[y].parent].right: t[t[y].parent].right=x
  else: t[t[y].parent].left=x
  t[x].right=y; t[y].parent=x
proc findNode(t: array[MaxOps+1,Node], rootValue: int, key: int64): int =
  result=rootValue
  while result!=0 and t[result].key!=key: result=if key<t[result].key: t[result].left else: t[result].right
proc insertNode(t: var array[MaxOps+1,Node], root: var int, initialZ: int) =
  var z=initialZ; var y=0; var x=root
  while x!=0: y=x; x=if t[z].key<t[x].key: t[x].left else: t[x].right
  t[z].parent=y
  if y==0: root=z
  elif t[z].key<t[y].key: t[y].left=z
  else: t[y].right=z
  t[z].left=0; t[z].right=0; t[z].red=true
  while t[t[z].parent].red:
    let p=t[z].parent; let g=t[p].parent
    if p==t[g].left:
      y=t[g].right
      if t[y].red: t[p].red=false; t[y].red=false; t[g].red=true; z=g
      else:
        if z==t[p].right: z=p; leftRotate(t,root,z)
        let pp=t[z].parent; let gg=t[pp].parent; t[pp].red=false; t[gg].red=true; rightRotate(t,root,gg)
    else:
      y=t[g].left
      if t[y].red: t[p].red=false; t[y].red=false; t[g].red=true; z=g
      else:
        if z==t[p].left: z=p; rightRotate(t,root,z)
        let pp=t[z].parent; let gg=t[pp].parent; t[pp].red=false; t[gg].red=true; leftRotate(t,root,gg)
  t[root].red=false
proc minimum(t: array[MaxOps+1,Node], initial: int): int =
  result=initial
  while t[result].left!=0: result=t[result].left
proc transplant(t: var array[MaxOps+1,Node], root: var int, u,v: int) =
  if t[u].parent==0: root=v
  elif u==t[t[u].parent].left: t[t[u].parent].left=v
  else: t[t[u].parent].right=v
  t[v].parent=t[u].parent
proc deleteFix(t: var array[MaxOps+1,Node], root: var int, initial: int) =
  var x=initial
  while x!=root and not t[x].red:
    let p=t[x].parent
    if x==t[p].left:
      var w=t[p].right
      if t[w].red: t[w].red=false; t[p].red=true; leftRotate(t,root,p); w=t[t[x].parent].right
      if not t[t[w].left].red and not t[t[w].right].red: t[w].red=true; x=t[x].parent
      else:
        if not t[t[w].right].red: t[t[w].left].red=false; t[w].red=true; rightRotate(t,root,w); w=t[t[x].parent].right
        let pp=t[x].parent; t[w].red=t[pp].red; t[pp].red=false; t[t[w].right].red=false; leftRotate(t,root,pp); x=root
    else:
      var w=t[p].left
      if t[w].red: t[w].red=false; t[p].red=true; rightRotate(t,root,p); w=t[t[x].parent].left
      if not t[t[w].right].red and not t[t[w].left].red: t[w].red=true; x=t[x].parent
      else:
        if not t[t[w].left].red: t[t[w].right].red=false; t[w].red=true; leftRotate(t,root,w); w=t[t[x].parent].left
        let pp=t[x].parent; t[w].red=t[pp].red; t[pp].red=false; t[t[w].left].red=false; rightRotate(t,root,pp); x=root
  t[x].red=false
proc deleteNode(t: var array[MaxOps+1,Node], root: var int, z: int) =
  var y=z; var x=0; var wasRed=t[y].red
  if t[z].left==0: x=t[z].right; transplant(t,root,z,t[z].right)
  elif t[z].right==0: x=t[z].left; transplant(t,root,z,t[z].left)
  else:
    y=minimum(t,t[z].right); wasRed=t[y].red; x=t[y].right
    if t[y].parent==z: t[x].parent=y
    else: transplant(t,root,y,t[y].right); t[y].right=t[z].right; t[t[y].right].parent=y
    transplant(t,root,z,y); t[y].left=t[z].left; t[t[y].left].parent=y; t[y].red=t[z].red
  if not wasRed: deleteFix(t,root,x)
proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits=cast[uint64](value)
  for b in 0..<8: output[offset+b]=uint8((bits shr (8*b)) and 0xff'u64)
proc red_black_tree_unique_key_ops*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl,exportc:"red_black_tree_unique_key_ops".} =
  if input.isNil or length<1: return -1
  let n64=input[0]
  if n64<0 or n64>MaxOps or length!=csize_t(1+2*n64): return -1
  let n=int(n64); var active: array[MaxOps,int64]; var ac=0; var sc=0
  for i in 0..<n:
    let op=input[1+2*i]; let key=input[2+2*i]
    if op<0 or op>2 or key < -2147483648'i64 or key > 2147483647'i64: return -1
    var found=ac; for j in 0..<ac:
      if active[j]==key: found=j; break
    if op==0:
      if found!=ac or ac>=MaxOps: return -1
      active[ac]=key; inc ac
    elif op==1: inc sc
    else:
      if found==ac: return -1
      for j in found+1..<ac: active[j-1]=active[j]
      dec ac
  var t: array[MaxOps+1,Node]; var root=0; var next=1; var results: array[MaxOps,int64]; var rc=0
  for i in 0..<n:
    let op=input[1+2*i]; let key=input[2+2*i]
    if op==0: t[next].key=key; insertNode(t,root,next); inc next
    elif op==1: results[rc]=int64(findNode(t,root,key)!=0); inc rc
    else: deleteNode(t,root,findNode(t,root,key))
  let bytes=(2+ac+sc)*8
  if output.isNil or capacity<csize_t(bytes): return -2
  putI64(output,0,int64(ac)); var stack: array[MaxOps,int]; var top=0; var current=root; var out=1
  while current!=0 or top>0:
    while current!=0: stack[top]=current; inc top; current=t[current].left
    dec top; current=stack[top]; putI64(output,out*8,t[current].key); inc out; current=t[current].right
  putI64(output,out*8,int64(sc)); inc out
  for i in 0..<sc: putI64(output,out*8,results[i]); inc out
  int64(bytes)
