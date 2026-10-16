const MaxN=1024
proc binary_tree_is_full*(input:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"binary_tree_is_full".}=
  if input.isNil or length<csize_t(2) or input[0]<1 or input[0]>MaxN:return -1
  let n=int(input[0]);let rootValue=input[1]
  if rootValue<0 or rootValue>=int64(n) or int(length)!=2+2*n:return -1
  var left,right,parents:array[MaxN,int]
  var stack:array[MaxN,int]
  var seen:array[MaxN,bool]
  var full=true
  for i in 0..<n:
    let l=input[2+2*i];let r=input[3+2*i]
    if l< -1 or l>=int64(n) or r< -1 or r>=int64(n) or l==int64(i) or r==int64(i):return -1
    left[i]=int(l);right[i]=int(r)
    if l>=0:inc parents[int(l)]
    if r>=0:inc parents[int(r)]
    if (l<0)!=(r<0):full=false
  let root=int(rootValue)
  if parents[root]!=0:return -1
  for i in 0..<n:
    if i!=root and parents[i]!=1:return -1
  var top=1;var visited=0;stack[0]=root
  while top>0:
    dec top
    let node=stack[top]
    if seen[node]:return -1
    seen[node]=true;inc visited
    if left[node]>=0:stack[top]=left[node];inc top
    if right[node]>=0:stack[top]=right[node];inc top
  if visited!=n:return -1
  if full: 1'i64 else: 0'i64
