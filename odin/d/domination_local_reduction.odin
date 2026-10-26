package domination_local_reduction

import "core:c"

put_word :: proc(out: [^]u8, offset: int, x: i64) {
	b := cast(u64)x
	for i := 0; i < 8; i += 1 { out[offset+i] = u8((b >> u64(8*i)) & 255) }
}

domination_local_reduction :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 135 do return -1
	n0,m0,p0 := input[0],input[1],input[2]
	if n0<1 || n0>12 || m0<0 || m0>66 || p0<0 || p0>=n0 || length != c.size_t(3+2*m0) do return -1
	n,m,p := int(n0),int(m0),int(p0)
	adj: [12][12]bool
	for e := 0; e < m; e += 1 { u0,v0 := input[3+2*e],input[4+2*e]; if u0<0 || v0<=u0 || v0>=n0 do return -1; u,v := int(u0),int(v0); if adj[u][v] do return -1; adj[u][v]=true;adj[v][u]=true }
	closed,exits,guards,prisoners: [12]bool
	closed[p]=true
	for u:=0;u<n;u+=1 { if adj[p][u] do closed[u]=true }
	for u:=0;u<n;u+=1 { if adj[p][u] { for x:=0;x<n;x+=1 { if adj[u][x] && !closed[x] { exits[u]=true;break } } } }
	for u:=0;u<n;u+=1 { if adj[p][u] && !exits[u] { for x:=0;x<n;x+=1 { if exits[x] && adj[u][x] { guards[u]=true;break } } } }
	np:=0
	for u:=0;u<n;u+=1 { if adj[p][u] && !exits[u] && !guards[u] { prisoners[u]=true;np+=1 } }
	if np==0 do return -1
	ids:[12]int;remap:[12]int
	for u:=0;u<n;u+=1 { remap[u]=-1 }
	kept:=0
	for u:=0;u<n;u+=1 { if !guards[u] && !prisoners[u] { ids[kept]=u;remap[u]=kept;kept+=1 } }
	k:=kept+1;leaf:=k-1;words:[25]i64;words[0]=i64(k)
	for i:=0;i<kept;i+=1 { words[1+i]=i64(ids[i]) };words[1+kept]=-1
	for i:=0;i<kept;i+=1 { for j:=0;j<kept;j+=1 { if adj[ids[i]][ids[j]] { words[1+k+i] |= i64(u64(1)<<u64(j)) } } }
	rp:=remap[p];words[1+k+rp] |= i64(u64(1)<<u64(leaf));words[1+k+leaf]=i64(u64(1)<<u64(rp))
	count:=1+2*k;bytes:=count*8
	if output==nil || capacity<c.size_t(bytes) do return -2
	for i:=0;i<count;i+=1 { put_word(output,8*i,words[i]) }
	return i64(bytes)
}
