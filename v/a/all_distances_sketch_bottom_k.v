module all_distances_sketch_bottom_k

fn put_i64(out &u8, offset int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { out[offset+b] = u8((bits >> (8*b)) & 255) } }
}

@[export: 'all_distances_sketch_bottom_k']
pub fn all_distances_sketch_bottom_k(input &i64,length usize,mut output &u8,capacity usize) i64 {
	if input == unsafe { nil } || length<6 || length>104 { return -1 }
	n0:=unsafe{input[0]};m0:=unsafe{input[1]};k0:=unsafe{input[2]};s0:=unsafe{input[3]}
	if n0<2||n0>10||m0<0||m0>n0*(n0-1)||k0<1||k0>n0||s0<0||s0>=n0{return -1}
	n:=int(n0);m:=int(m0);k:=int(k0);source:=int(s0);if length!=usize(4+n+2*m){return -1}
	mut rank:=[10]i64{};mut used:=[10]bool{}
	for i in 0 .. n { r:=unsafe{input[4+i]};if r<0||r>=n0||used[int(r)]{return -1};used[int(r)]=true;rank[i]=r }
	mut adj:=[10][10]bool{}
	for e in 0 .. m { u0:=unsafe{input[4+n+2*e]};v0:=unsafe{input[5+n+2*e]};if u0<0||u0>=n0||v0<0||v0>=n0||u0==v0{return -1};u:=int(u0);v:=int(v0);if adj[u][v]{return -1};adj[u][v]=true }
	mut dist:=[10]i64{};for i in 0 .. n { dist[i]=-1 }
	mut queue:=[10]int{};mut head:=0;mut tail:=0;dist[source]=0;queue[tail]=source;tail++
	for head<tail { u:=queue[head];head++;for v in 0 .. n { if adj[u][v]&&dist[v]<0 {dist[v]=dist[u]+1;queue[tail]=v;tail++} } }
	mut staged:=[21]i64{};mut count:=0
	for d in 0 .. n { for v in 0 .. n { if dist[v]!=i64(d){continue};mut less:=0;for x in 0 .. n {if dist[x]>=0&&(dist[x]<dist[v]||(dist[x]==dist[v]&&x<=v))&&rank[x]<rank[v]{less++}};if less<k{staged[1+2*count]=i64(v);staged[2+2*count]=dist[v];count++}} }
	staged[0]=i64(count);words:=1+2*count;bytes:=8*words
	if output==unsafe{nil}||capacity<usize(bytes){return -2}
	for i in 0 .. words { put_i64(mut output,8*i,staged[i]) }
	return i64(bytes)
}
