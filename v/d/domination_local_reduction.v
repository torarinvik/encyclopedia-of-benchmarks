module domination_local_reduction

fn put_word(mut output &u8, offset int, value i64) {
	bits:=u64(value)
	for b in 0 .. 8 { unsafe { output[offset+b]=u8((bits >> u64(8*b)) & 255) } }
}

@[export: 'domination_local_reduction']
pub fn domination_local_reduction(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input==nil || length<3 || length>135 { return -1 }
	unsafe {
		n0,m0,p0:=input[0],input[1],input[2]
		if n0<1 || n0>12 || m0<0 || m0>66 || p0<0 || p0>=n0 || length!=usize(3+2*m0) { return -1 }
		n,m,p:=int(n0),int(m0),int(p0)
		mut adj:=[]bool{len:144,init:false}
		for e in 0 .. m { u0,v0:=input[3+2*e],input[4+2*e];if u0<0 || v0<=u0 || v0>=n0{return -1};u,v:=int(u0),int(v0);if adj[u*12+v]{return -1};adj[u*12+v]=true;adj[v*12+u]=true }
		mut closed:=[]bool{len:12,init:false};mut exits:=[]bool{len:12,init:false};mut guards:=[]bool{len:12,init:false};mut prisoners:=[]bool{len:12,init:false};closed[p]=true
		for u in 0 .. n { if adj[p*12+u] { closed[u]=true } }
		for u in 0 .. n { if adj[p*12+u] { for x in 0 .. n { if adj[u*12+x] && !closed[x] { exits[u]=true;break } } } }
		for u in 0 .. n { if adj[p*12+u] && !exits[u] { for x in 0 .. n { if exits[x] && adj[u*12+x] { guards[u]=true;break } } } }
		mut np:=0
		for u in 0 .. n { if adj[p*12+u] && !exits[u] && !guards[u] { prisoners[u]=true;np++ } }
		if np==0{return -1}
		mut ids:=[]int{len:12,init:0};mut remap:=[]int{len:12,init:-1};mut kept:=0
		for u in 0 .. n { if !guards[u] && !prisoners[u] { ids[kept]=u;remap[u]=kept;kept++ } }
		k:=kept+1;leaf:=k-1;mut words:=[]i64{len:25,init:0};words[0]=i64(k)
		for i in 0 .. kept { words[1+i]=i64(ids[i]) };words[1+kept]= -1
		for i in 0 .. kept { for j in 0 .. kept { if adj[ids[i]*12+ids[j]] { words[1+k+i] |= i64(u64(1)<<u64(j)) } } }
		rp:=remap[p];words[1+k+rp] |= i64(u64(1)<<u64(leaf));words[1+k+leaf]=i64(u64(1)<<u64(rp))
		count:=1+2*k;bytes:=count*8;if output==nil || capacity<usize(bytes){return -2}
		for i in 0 .. count { put_word(mut output,8*i,words[i]) }
		return i64(bytes)
	}
}
