proc kahn*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"kahn".}=
 if v.isNil or n<2 or n>258:return -2
 let nv=v[0];let ne=v[1]
 if nv<0 or nv>32 or ne<0 or ne>128 or n!=csize_t(2+2*ne):return -2
 var adj:array[32,array[32,bool]];var indegree:array[32,int64];var q:array[32,int]
 for i in 0..<int(ne):
  let a=v[2+2*i];let b=v[3+2*i]
  if a<0 or a>=nv or b<0 or b>=nv:return -2
  if not adj[int(a)][int(b)]:adj[int(a)][int(b)]=true;inc indegree[int(b)]
 var head=0;var tail=0
 for i in 0..<int(nv):if indegree[i]==0:q[tail]=i;inc tail
 while head<tail:
  let x=q[head];inc head
  for y in 0..<int(nv):
   if adj[x][y]:
    dec indegree[y]
    if indegree[y]==0:q[tail]=y;inc tail
 if tail==int(nv):return nv
 -1
