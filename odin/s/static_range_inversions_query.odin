package static_range_inversions_query

import "core:c"

MAX_N :: 128
MAX_Q :: 32
Query :: struct { left, right, id, block_id: int }

lower_bound :: proc "contextless" (values: [^]i64, count: int, target: i64) -> int {
	lo, hi := 0, count
	for lo < hi { mid:=lo+(hi-lo)/2;if values[mid]<target{lo=mid+1}else{hi=mid} }
	return lo
}
bit_sum :: proc "contextless" (bit: [^]i64, count: int) -> i64 {
	i:=count;sum:=i64(0);for i>0{sum+=bit[i];i-=i & (-i)};return sum
}
bit_add :: proc "contextless" (bit: [^]i64, rank: int, delta: i64) {
	i:=rank+1;for i<=MAX_N{bit[i]+=delta;i+=i & (-i)}
}
before :: proc "contextless" (a,b: Query) -> bool {
	if a.block_id!=b.block_id{return a.block_id<b.block_id}
	if a.right!=b.right{if (a.block_id&1)==1{return a.right>b.right};return a.right<b.right}
	return a.id<b.id
}
put64 :: proc "contextless" (output: [^]u8,offset: int,value: i64) {
	bits:=u64(value);for byte:=0;byte<8;byte+=1{output[offset+byte]=u8((bits>>(8*byte))&255)}
}

@(export)
static_range_inversions_query :: proc "c" (input: [^]i64,length: c.size_t,
		output: [^]u8,capacity: c.size_t) -> i64 {
	if input==nil||length<2||length>195 do return -1
	nv,qv:=input[0],input[1];if nv<1||nv>128||qv<1||qv>32 do return -1
	n,q:=int(nv),int(qv);if int(length)!=2+n+2*q do return -1
	values,sorted:=[MAX_N]i64{},[MAX_N]i64{}
	for i:=0;i<n;i+=1{values[i]=input[2+i];if values[i]<0||values[i]>1_000_000_000 do return -1;sorted[i]=values[i]}
	for i:=1;i<n;i+=1{x:=sorted[i];j:=i;for j>0&&sorted[j-1]>x{sorted[j]=sorted[j-1];j-=1};sorted[j]=x}
	distinct:=0;for i:=0;i<n;i+=1{if distinct==0||sorted[i]!=sorted[distinct-1]{sorted[distinct]=sorted[i];distinct+=1}}
	ranks:=[MAX_N]int{};for i:=0;i<n;i+=1{ranks[i]=lower_bound(&sorted[0],distinct,values[i])}
	block_size:=1;for (block_size+1)*(block_size+1)<=n{block_size+=1}
	queries:=[MAX_Q]Query{};off:=2+n
	for k:=0;k<q;k+=1{l,r:=input[off],input[off+1];off+=2;if l<0||l>=r||r>nv do return -1;queries[k]=Query{int(l),int(r),k,int(l)/block_size}}
	for i:=1;i<q;i+=1{x:=queries[i];j:=i;for j>0&&before(x,queries[j-1]){queries[j]=queries[j-1];j-=1};queries[j]=x}
	bit:=[MAX_N+1]i64{};answers:=[MAX_Q]i64{};left,right,window:=0,0,0;inversions:=i64(0)
	for qi:=0;qi<q;qi+=1{query:=queries[qi]
		for left>query.left{left-=1;rank:=ranks[left];inversions+=bit_sum(&bit[0],rank);bit_add(&bit[0],rank,1);window+=1}
		for right<query.right{rank:=ranks[right];inversions+=i64(window)-bit_sum(&bit[0],rank+1);bit_add(&bit[0],rank,1);window+=1;right+=1}
		for left<query.left{rank:=ranks[left];inversions-=bit_sum(&bit[0],rank);bit_add(&bit[0],rank,-1);window-=1;left+=1}
		for right>query.right{right-=1;rank:=ranks[right];inversions-=i64(window)-bit_sum(&bit[0],rank+1);bit_add(&bit[0],rank,-1);window-=1}
		answers[query.id]=inversions
	}
	bytes:=8*q;if output==nil||int(capacity)<bytes do return -2
	for k:=0;k<q;k+=1{put64(output,8*k,answers[k])};return i64(bytes)
}
