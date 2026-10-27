fn min_hash_k_partition_put(mut output &u8, position int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[position+b] = u8((bits >> u64(8*b)) & 255) } }
}
@[export: 'min_hash_k_partition']
pub fn min_hash_k_partition(input &i64,length usize,mut output &u8,capacity usize)i64{
	unsafe {
		if input==nil||length<2||length>66{return -1}
		k0:=input[0];n0:=input[1]
		if k0<1||k0>8||n0<0||n0>32||length!=usize(2+2*n0){return -1}
		mut ids:=[]i64{len:int(k0),init:-1};mut ranks:=[]i64{len:int(k0),init:1001}
		for id in 0..int(n0){bucket:=input[2+2*id];rank:=input[3+2*id];if bucket<0||bucket>=k0||rank<0||rank>1000{return -1}
			b:=int(bucket);if ids[b]<0||rank<ranks[b]||(rank==ranks[b]&&i64(id)<ids[b]){ids[b]=i64(id);ranks[b]=rank}}
		mut staged:=[]i64{len:16,init:0};for b in 0..int(k0){staged[2*b]=ids[b];staged[2*b+1]=ranks[b]}
		required:=int(2*k0*8);if output==nil||capacity<usize(required){return -2}
		for i in 0..int(2*k0){min_hash_k_partition_put(mut output,i*8,staged[i])}
		return i64(required)
	}
}
