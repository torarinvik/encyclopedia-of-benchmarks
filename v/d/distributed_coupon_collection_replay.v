@[export: 'distributed_coupon_collection_replay']
pub fn distributed_coupon_collection_replay(input &i64,length usize,output &u8,capacity usize)i64{
	unsafe{
		if input==nil||length<4||length>76{return -1}
		n64:=input[0];c64:=input[1];copies:=input[2];steps64:=input[3]
		if n64<2||n64>8||c64<1||c64>8||copies<1||copies>n64||steps64<1||steps64>8||length!=usize(4+n64+n64*steps64){return -1}
		n:=int(n64);coupons:=int(c64);steps:=int(steps64);full:=(u64(1)<<coupons)-1
		mut bins:=[]u64{len:n,init:0}
		for b in 0..n{raw:=input[4+b];if raw<0||(u64(raw)&~full)!=0{return -1};bins[b]=u64(raw)}
		for coupon in 0..coupons{mut count:=0;for b in 0..n{if ((bins[b]>>coupon)&1)!=0{count++}};if count<int(copies){return -1}}
		tape_at:=4+n
		for i in 0..n*steps{if input[tape_at+i]!=0&&input[tape_at+i]!=1{return -1}}
		if output==nil||capacity<16{return -2}
		mut collected:=u64(0);mut singleton_steps:=i64(0)
		for step in 0..steps{mut open_count:=0;mut opened_bin:=0;for bin in 0..n{if input[tape_at+step*n+bin]==1{open_count++;opened_bin=bin}};if open_count==1{singleton_steps++;collected|=bins[opened_bin]}}
		mut fields:=[2]i64{i64(collected),singleton_steps}
		for i in 0..2{bits:=u64(fields[i]);for b in 0..8{output[8*i+b]=u8((bits>>(8*b))&255)}}
		return 16
	}
}
