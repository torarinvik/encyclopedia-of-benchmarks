## Return the Ruby BFS seen/visited orders and ordered parent/distance pairs.
proc putI64Le(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[word*8+b] = uint8((bits shr (8*b)) and 0xFF'u64)
proc bfs_result_tree*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"bfs_result_tree".} =
  if input.isNil or length<3:return -1
  let nv=input[0];let mv=input[1];let sv=input[2]
  if nv<1 or nv>32 or mv<0 or mv>126 or sv<0 or sv>=nv or length!=csize_t(3+2*mv):return -1
  let n=int(nv);let m=int(mv);let start=int(sv)
  var adj:array[32,array[126,int]];var degree:array[32,int];var seen:array[32,bool];var parent:array[32,int64];var distance:array[32,int64];var queue:array[32,int];var order:array[32,int]
  for v in 0..<32:parent[v] = -1;distance[v] = -1
  for e in 0..<m:
    let a=input[3+2*e];let b=input[4+2*e]
    if a<0 or a>=nv or b<0 or b>=nv:return -1
    adj[int(a)][degree[int(a)]]=int(b);inc degree[int(a)]
  var head=0;var tail=0;var count=0;seen[start]=true;distance[start]=0;queue[tail]=start;inc tail
  while head<tail:
    let v=queue[head];inc head;order[count]=v;inc count
    for j in 0..<degree[v]:
      let w=adj[v][j]
      if not seen[w]:seen[w]=true;parent[w]=int64(v);distance[w]=distance[v]+1;queue[tail]=w;inc tail
  let words=4+6*count
  if output.isNil or capacity<csize_t(words*8):return -2
  var k=0;putI64Le(output,k,int64(count));inc k
  for i in 0..<count:putI64Le(output,k,int64(order[i]));inc k
  putI64Le(output,k,int64(count));inc k
  for i in 0..<count:putI64Le(output,k,int64(order[i]));inc k
  putI64Le(output,k,int64(count));inc k
  for i in 0..<count:let v=order[i];putI64Le(output,k,int64(v));inc k;putI64Le(output,k,parent[v]);inc k
  putI64Le(output,k,int64(count));inc k
  for i in 0..<count:let v=order[i];putI64Le(output,k,int64(v));inc k;putI64Le(output,k,distance[v]);inc k
  int64(words*8)
