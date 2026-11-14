import std/algorithm

type SweepTree = object
  key: array[65,int64]
  height, left, right: array[65,int]

proc nodeHeight(tree: var SweepTree, node: int): int =
  if node==0: 0 else: tree.height[node]
proc refresh(tree: var SweepTree, node: int) =
  tree.height[node]=1+max(nodeHeight(tree,tree.left[node]),nodeHeight(tree,tree.right[node]))
proc rotateRight(tree: var SweepTree, root: int): int =
  let pivot=tree.left[root]
  tree.left[root]=tree.right[pivot]; tree.right[pivot]=root
  refresh(tree,root); refresh(tree,pivot)
  pivot
proc rotateLeft(tree: var SweepTree, root: int): int =
  let pivot=tree.right[root]
  tree.right[root]=tree.left[pivot]; tree.left[pivot]=root
  refresh(tree,root); refresh(tree,pivot)
  pivot
proc balance(tree: var SweepTree, root: int): int =
  refresh(tree,root)
  let difference=nodeHeight(tree,tree.left[root])-nodeHeight(tree,tree.right[root])
  if difference>1:
    let child=tree.left[root]
    if nodeHeight(tree,tree.left[child])<nodeHeight(tree,tree.right[child]):
      tree.left[root]=rotateLeft(tree,child)
    return rotateRight(tree,root)
  if difference< -1:
    let child=tree.right[root]
    if nodeHeight(tree,tree.right[child])<nodeHeight(tree,tree.left[child]):
      tree.right[root]=rotateRight(tree,child)
    return rotateLeft(tree,root)
  root
proc insert(tree: var SweepTree, root,index: int): int =
  if root==0: return index
  if tree.key[index]<tree.key[root]: tree.left[root]=insert(tree,tree.left[root],index)
  else: tree.right[root]=insert(tree,tree.right[root],index)
  balance(tree,root)
proc erase(tree: var SweepTree, root: int, key: int64): int =
  if root==0: return 0
  if key<tree.key[root]: tree.left[root]=erase(tree,tree.left[root],key)
  elif key>tree.key[root]: tree.right[root]=erase(tree,tree.right[root],key)
  elif tree.left[root]==0: return tree.right[root]
  elif tree.right[root]==0: return tree.left[root]
  else:
    var successor=tree.right[root]
    while tree.left[successor]!=0: successor=tree.left[successor]
    let replacement=tree.key[successor]
    tree.key[root]=replacement
    tree.right[root]=erase(tree,tree.right[root],replacement)
  balance(tree,root)
proc rangeBest(tree: var SweepTree, root: int, low,high,x,y,initial: int64): int64 =
  if root==0: return initial
  let key=tree.key[root]
  var best=initial
  if key>=low: best=rangeBest(tree,tree.left[root],low,high,x,y,best)
  if key>=low and key<=high:
    let dx=x-(key mod 2001-1000)
    let dy=y-(key div 2001-1000)
    best=min(best,dx*dx+dy*dy)
  if key<=high: best=rangeBest(tree,tree.right[root],low,high,x,y,best)
  best

proc closest_pair_sweep*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "closest_pair_sweep".} =
  if input.isNil or length<5 or length>130 or input[0]<2 or input[0]>64: return -1
  let n=int(input[0])
  if length!=csize_t(1+2*n): return -1
  var points=newSeq[int64](n)
  for i in 0 ..< n:
    let x=input[1+2*i]; let y=input[2+2*i]
    if x< -1000 or x>1000 or y< -1000 or y>1000: return -1
    points[i]=(x+1000)*2001+y+1000
  points.sort()
  for i in 1 ..< n:
    if points[i]==points[i-1]: return 0
  var tree: SweepTree
  var root=0
  var oldest=0
  var best=8000001'i64
  for i in 0 ..< n:
    let x=points[i] div 2001-1000
    let y=points[i] mod 2001-1000
    while oldest<i:
      let oldX=points[oldest] div 2001-1000
      let dx=x-oldX
      if dx*dx<=best: break
      let oldY=points[oldest] mod 2001-1000
      root=erase(tree,root,(oldY+1000)*2001+oldX+1000)
      inc oldest
    var lo=0'i64; var hi=3000'i64
    while lo<hi:
      let middle=(lo+hi+1) div 2
      if middle*middle<=best: lo=middle else: hi=middle-1
    best=rangeBest(tree,root,(y-lo+1000)*2001,(y+lo+1000)*2001+2000,x,y,best)
    let index=i+1
    tree.key[index]=(y+1000)*2001+x+1000
    tree.height[index]=1
    root=insert(tree,root,index)
  best
