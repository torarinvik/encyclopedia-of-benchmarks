package k_quadtree_sampled_point_subdivision

import "core:c"

put_i64_le :: proc "contextless" (output: [^]u8, at: usize, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { output[at+usize(b)] = u8((bits >> u64(8*b)) & 255) }
}

@(export)
k_quadtree_sampled_point_subdivision :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input==nil || length<3 || length>68 { return -1 }
	nv,kv,dv := input[0],input[1],input[2]
	if nv<1 || nv>32 || kv<1 || kv>nv || dv<1 || dv>8 { return -1 }
	n,k,depth := int(nv),int(kv),int(dv)
	if length!=c.size_t(3+2*n) { return -1 }
	side := i64(1)<<depth
	keys: [32]u32
	for i:=0;i<n;i+=1 {
		x,y := input[3+2*i],input[4+2*i]
		if x<0 || y<0 || x>=side || y>=side { return -1 }
		key:=u32(0)
		for bit:=depth-1;bit>=0;bit-=1 { key=(key<<2)|((((u32(x)>>u32(bit))&1)<<1)|((u32(y)>>u32(bit))&1)) }
		keys[i]=key
	}
	for i:=1;i<n;i+=1 { value:=keys[i];j:=i;for j>0 && keys[j-1]>value { keys[j]=keys[j-1];j-=1 };keys[j]=value }
	for i:=1;i<n;i+=1 { if keys[i]==keys[i-1] { return -1 } }
	samples:=(n-1)/k+1
	split_depth:[31]int
	split_prefix:[31]u32
	count:=0
	for i:=0;i+1<samples;i+=1 {
		a,b:=keys[i*k],keys[(i+1)*k];common:=0
		for common<depth { shift:=2*(depth-common-1);if ((a>>u32(shift))&3)!=((b>>u32(shift))&3){break};common+=1 }
		prefix:=u32(0);if common>0 { prefix=a>>u32(2*(depth-common)) }
		j:=0;for j<count && (split_depth[j]!=common || split_prefix[j]!=prefix){j+=1}
		if j==count { split_depth[count]=common;split_prefix[count]=prefix;count+=1 }
	}
	for i:=1;i<count;i+=1 {
		d,p:=split_depth[i],split_prefix[i];start:=p<<u32(2*(depth-d));j:=i
		for j>0 { ps:=split_prefix[j-1]<<u32(2*(depth-split_depth[j-1]));if ps<start || (ps==start && split_depth[j-1]<=d){break};split_depth[j]=split_depth[j-1];split_prefix[j]=split_prefix[j-1];j-=1 }
		split_depth[j]=d;split_prefix[j]=p
	}
	bytes:=8*(1+2*count);if output==nil || capacity<c.size_t(bytes){return -2}
	put_i64_le(output,0,i64(count));for i:=0;i<count;i+=1 { put_i64_le(output,8*(1+2*i),i64(split_depth[i]));put_i64_le(output,8*(2+2*i),i64(split_prefix[i])) }
	return i64(bytes)
}
