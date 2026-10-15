module bfs_result_tree
fn put_i64_le(mut output &u8, word int, value i64) { mut bits:=u64(value);for b in 0..8{unsafe{output[word*8+b]=u8(bits&255)};bits>>=8} }
@[export: 'bfs_result_tree']
pub fn bfs_result_tree(input &i64,length usize,mut output &u8,capacity usize) i64 {
 if unsafe{input==nil}||length<3{return -1};nv:=input[0];mv:=input[1];sv:=input[2];if nv<1||nv>32||mv<0||mv>126||sv<0||sv>=nv||length!=usize(3+2*mv){return -1};n:=int(nv);m:=int(mv);start:=int(sv)
 unsafe{mut adj:=[32][126]int{};mut degree:=[32]int{};mut seen:=[32]bool{};mut parent:=[32]i64{};mut distance:=[32]i64{};mut queue:=[32]int{};mut order:=[32]int{};for i in 0..32{parent[i]=-1;distance[i]=-1}
 for e in 0..m{a:=input[3+2*e];b:=input[4+2*e];if a<0||a>=nv||b<0||b>=nv{return -1};ai:=int(a);adj[ai][degree[ai]]=int(b);degree[ai]++}
 mut head:=0;mut tail:=0;mut count:=0;seen[start]=true;distance[start]=0;queue[tail]=start;tail++
 for head<tail{v:=queue[head];head++;order[count]=v;count++;for j in 0..degree[v]{w:=adj[v][j];if !seen[w]{seen[w]=true;parent[w]=i64(v);distance[w]=distance[v]+1;queue[tail]=w;tail++}}}
 words:=4+6*count;if output==nil||capacity<words*8{return -2};mut k:=0;put_i64_le(mut output,k,i64(count));k++;for i in 0..count{put_i64_le(mut output,k,i64(order[i]));k++};put_i64_le(mut output,k,i64(count));k++;for i in 0..count{put_i64_le(mut output,k,i64(order[i]));k++};put_i64_le(mut output,k,i64(count));k++;for i in 0..count{v:=order[i];put_i64_le(mut output,k,i64(v));k++;put_i64_le(mut output,k,parent[v]);k++};put_i64_le(mut output,k,i64(count));k++;for i in 0..count{v:=order[i];put_i64_le(mut output,k,i64(v));k++;put_i64_le(mut output,k,distance[v]);k++};return i64(words*8)}
}
