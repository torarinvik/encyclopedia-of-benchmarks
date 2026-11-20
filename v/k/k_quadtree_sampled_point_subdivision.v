fn put_i64_le(mut output &u8, at int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[at+b] = u8((bits>>(b*8))&255) } }
}

@[export: 'k_quadtree_sampled_point_subdivision']
pub fn k_quadtree_sampled_point_subdivision(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if isnil(input)||length<3||length>68{return -1}
	nv:=unsafe{input[0]};kv:=unsafe{input[1]};dv:=unsafe{input[2]}
	if nv<1||nv>32||kv<1||kv>nv||dv<1||dv>8{return -1}
	n:=int(nv);k:=int(kv);depth:=int(dv)
	if int(length)!=3+2*n{return -1}
	side:=i64(1)<<depth
	mut keys:=[32]u32{}
	for i in 0..n{
		x:=unsafe{input[3+2*i]};y:=unsafe{input[4+2*i]}
		if x<0||y<0||x>=side||y>=side{return -1}
		mut key:=u32(0)
		for bit:=depth-1;bit>=0;bit--{key=(key<<2)|((((u32(x)>>bit)&1)<<1)|((u32(y)>>bit)&1))}
		keys[i]=key
	}
	for i in 1..n{value:=keys[i];mut j:=i;for j>0&&keys[j-1]>value{keys[j]=keys[j-1];j--};keys[j]=value}
	for i in 1..n{if keys[i]==keys[i-1]{return -1}}
	samples:=(n-1)/k+1
	mut split_depth:=[31]int{}
	mut split_prefix:=[31]u32{}
	mut count:=0
	for i in 0..(samples-1){
		a:=keys[i*k];b:=keys[(i+1)*k];mut common:=0
		for common<depth{shift:=2*(depth-common-1);if ((a>>shift)&3)!=((b>>shift)&3){break};common++}
		prefix:=u32(0);if common>0{prefix=a>>(2*(depth-common))}
		mut j:=0;for j<count&&(split_depth[j]!=common||split_prefix[j]!=prefix){j++}
		if j==count{split_depth[count]=common;split_prefix[count]=prefix;count++}
	}
	for i in 1..count{
		d:=split_depth[i];p:=split_prefix[i];start:=p<<(2*(depth-d));mut j:=i
		for j>0{ps:=split_prefix[j-1]<<(2*(depth-split_depth[j-1]));if ps<start||(ps==start&&split_depth[j-1]<=d){break};split_depth[j]=split_depth[j-1];split_prefix[j]=split_prefix[j-1];j--}
		split_depth[j]=d;split_prefix[j]=p
	}
	bytes:=8*(1+2*count);if isnil(output)||capacity<usize(bytes){return -2}
	put_i64_le(mut output,0,i64(count));for i in 0..count{put_i64_le(mut output,8*(1+2*i),i64(split_depth[i]));put_i64_le(mut output,8*(2+2*i),i64(split_prefix[i]))}
	return i64(bytes)
}
