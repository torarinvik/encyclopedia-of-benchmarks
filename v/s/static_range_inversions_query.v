module static_range_inversions_query

const max_n = 128
const max_q = 32

struct Query {
	left int
	right int
	id int
	block_id int
}

fn lower_bound(values []i64, count int, target i64) int {
	mut lo := 0
	mut hi := count
	for lo < hi { mid := lo + (hi-lo)/2; if values[mid] < target { lo=mid+1 } else { hi=mid } }
	return lo
}
fn bit_sum(bit []i64, count int) i64 {
	mut i:=count;mut sum:=i64(0)
	for i>0 { sum+=bit[i];i-=i & (-i) }
	return sum
}
fn bit_add(mut bit []i64, rank int, delta i64) {
	mut i:=rank+1
	for i<=max_n { bit[i]+=delta;i+=i & (-i) }
}
fn before(a Query,b Query) bool {
	if a.block_id!=b.block_id {return a.block_id<b.block_id}
	if a.right!=b.right {if (a.block_id & 1)==1{return a.right>b.right};return a.right<b.right}
	return a.id<b.id
}
fn put64(mut output &u8,offset int,value i64){bits:=u64(value);for b in 0..8{unsafe{output[offset+b]=u8((bits>>(8*b))&255)}}}

@[export: 'static_range_inversions_query']
pub fn static_range_inversions_query(input &i64,length usize,mut output &u8,capacity usize) i64 {
	if unsafe{input==nil}||length<2||length>195{return -1}
	nv:=unsafe{input[0]};qv:=unsafe{input[1]};if nv<1||nv>max_n||qv<1||qv>max_q{return -1}
	n:=int(nv);q:=int(qv);if length!=usize(2+n+2*q){return -1}
	mut values:=[]i64{len:max_n};mut sorted:=[]i64{len:max_n}
	for i in 0..n{values[i]=unsafe{input[2+i]};if values[i]<0||values[i]>1_000_000_000{return -1};sorted[i]=values[i]}
	for i in 1..n{value:=sorted[i];mut j:=i;for j>0&&sorted[j-1]>value{sorted[j]=sorted[j-1];j--};sorted[j]=value}
	mut distinct:=0;for i in 0..n{if distinct==0||sorted[i]!=sorted[distinct-1]{sorted[distinct]=sorted[i];distinct++}}
	mut ranks:=[]int{len:max_n};for i in 0..n{ranks[i]=lower_bound(sorted,distinct,values[i])}
	mut block_size:=1;for (block_size+1)*(block_size+1)<=n{block_size++}
	mut queries:=[]Query{len:max_q};mut off:=2+n
	for k in 0..q{l:=unsafe{input[off]};r:=unsafe{input[off+1]};off+=2;if l<0||l>=r||r>nv{return -1};queries[k]=Query{left:int(l),right:int(r),id:k,block_id:int(l)/block_size}}
	for i in 1..q{value:=queries[i];mut j:=i;for j>0&&before(value,queries[j-1]){queries[j]=queries[j-1];j--};queries[j]=value}
	mut bit:=[]i64{len:max_n+1};mut answers:=[]i64{len:max_q};mut left:=0;mut right:=0;mut window:=0;mut inversions:=i64(0)
	for qi in 0..q{query:=queries[qi]
		for left>query.left{left--;rank:=ranks[left];inversions+=bit_sum(bit,rank);bit_add(mut bit,rank,1);window++}
		for right<query.right{rank:=ranks[right];inversions+=i64(window)-bit_sum(bit,rank+1);bit_add(mut bit,rank,1);window++;right++}
		for left<query.left{rank:=ranks[left];inversions-=bit_sum(bit,rank);bit_add(mut bit,rank,-1);window--;left++}
		for right>query.right{right--;rank:=ranks[right];inversions-=i64(window)-bit_sum(bit,rank+1);bit_add(mut bit,rank,-1);window--}
		answers[query.id]=inversions
	}
	bytes:=8*q;if unsafe{output==nil}||int(capacity)<bytes{return -2};for k in 0..q{put64(mut output,8*k,answers[k])};return i64(bytes)
}
