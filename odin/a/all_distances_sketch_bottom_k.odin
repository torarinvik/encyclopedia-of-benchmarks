package all_distances_sketch_bottom_k

import "core:c"

put_i64 :: proc(out: [^]u8, offset: int, x: i64) {
	b := u64(x)
	for i in 0..<8 { out[offset+i] = u8((b >> (8*i)) & 255) }
}

@(export)
all_distances_sketch_bottom_k :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > 104 do return -1
	n0,m0,k0,s0 := input[0],input[1],input[2],input[3]
	if n0<2 || n0>10 || m0<0 || m0>n0*(n0-1) || k0<1 || k0>n0 || s0<0 || s0>=n0 do return -1
	n,m,k,source := int(n0),int(m0),int(k0),int(s0)
	if int(length)!=4+n+2*m do return -1
	rank:[10]i64;used:[10]bool
	for i in 0..<n { r:=input[4+i];if r<0 || r>=n0 || used[int(r)] do return -1;used[int(r)]=true;rank[i]=r }
	adj:[10][10]bool
	for e in 0..<m { u0,v0:=input[4+n+2*e],input[5+n+2*e];if u0<0||u0>=n0||v0<0||v0>=n0||u0==v0 do return -1;u,v:=int(u0),int(v0);if adj[u][v] do return -1;adj[u][v]=true }
	dist:[10]i64;for i in 0..<n { dist[i]=-1 }
	queue:[10]int;head,tail:=0,0;dist[source]=0;queue[tail]=source;tail+=1
	for head<tail { u:=queue[head];head+=1;for v in 0..<n { if adj[u][v]&&dist[v]<0 { dist[v]=dist[u]+1;queue[tail]=v;tail+=1 } } }
	staged:[21]i64;count:=0
	for d in 0..<n { for v in 0..<n { if dist[v]!=i64(d) do continue;less:=0;for x in 0..<n { if dist[x]>=0&&(dist[x]<dist[v]||(dist[x]==dist[v]&&x<=v))&&rank[x]<rank[v] { less+=1 } };if less<k { staged[1+2*count]=i64(v);staged[2+2*count]=dist[v];count+=1 } } }
	staged[0]=i64(count);words:=1+2*count;bytes:=8*words
	if output==nil||capacity<c.size_t(bytes) do return -2
	for i in 0..<words { put_i64(output,8*i,staged[i]) }
	return i64(bytes)
}
