module secretary_1e_threshold

const max_n = 16
const max_input = 17
const sample_counts = [17]int{0,0,0,1,1,1,2,2,2,3,3,4,4,4,5,5,5}

fn put_i64(mut out &u8, at int, value i64) { bits:=u64(value);for j in 0..8 {unsafe{out[at+j]=u8((bits>>(8*j))&255)}} }

@[export: 'secretary_1e_threshold']
pub fn secretary_1e_threshold(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input==nil||length<4||length>max_input{return -1}
		n64:=input[0];if n64<3||n64>max_n||length!=usize(n64+1){return -1};n:=int(n64)
		mut seen:=[max_n+1]bool{}
		for i in 0..n {rank:=input[i+1];if rank<1||rank>n64||seen[int(rank)]{return -1};seen[int(rank)]=true}
		observed:=sample_counts[n];mut threshold:=input[1]
		for i in 1..observed {if input[i+1]>threshold{threshold=input[i+1]}}
		mut selected:=i64(-1)
		for i in observed..n {if input[i+1]>threshold{selected=i64(i);break}}
		if output==nil||capacity<8{return -2};mut staged:=[8]u8{};put_i64(mut &staged[0],0,selected);for i in 0..8{output[i]=staged[i]};return 8
	}
}
