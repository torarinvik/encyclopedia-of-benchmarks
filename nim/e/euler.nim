proc euler*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "euler".} =
  if v == nil or n < 4 or n > 516: return -2
  let count=v[0]; let source=v[1]; let dest=v[2]; let edges=v[3]
  if count<1 or count>32 or source<0 or source>=count or dest<0 or dest>=count or edges<0 or edges>256 or n!=csize_t(4+2*edges):return -2
  var adj:array[32,uint64];var degree:array[32,int64]
  for i in 0..<int(edges):
    let x=v[4+2*i];let y=v[5+2*i]
    if x<0 or y<0 or x>=count or y>=count or x==y:return -2
    let bx=1'u64 shl int(x);let by=1'u64 shl int(y)
    if (adj[int(x)] and by)!=0:return -2
    adj[int(x)]=adj[int(x)] or by;adj[int(y)]=adj[int(y)] or bx
    inc degree[int(x)];inc degree[int(y)]
  var odd=0
  for i in 0..<int(count):
    let want=source!=dest and (int64(i)==source or int64(i)==dest)
    let isOdd=(degree[i] mod 2)!=0
    if isOdd!=want:return 0
    if isOdd:inc odd
  if source == dest:
    return (if odd == 0: 1'i64 else: 0'i64)
  return (if odd == 2: 1'i64 else: 0'i64)
