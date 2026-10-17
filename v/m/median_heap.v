module median_heap

const max_operations = 256
const max_input_length = 514
const max_live_values = 64
const nil_sentinel = i64(-9223372036854775807 - 1)

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> u64(8 * byte)) & 255) } }
}
fn push_max(mut heap [64]i32, mut count int, value i32) { mut p:=count;count++;for p>0&&heap[(p-1)/2]<value{q:=(p-1)/2;heap[p]=heap[q];p=q};heap[p]=value }
fn pop_max(mut heap [64]i32, mut count int) i32 { result:=heap[0];count--;value:=heap[count];if count==0{return result};mut p:=0;for 2*p+1<count{mut c:=2*p+1;if c+1<count&&heap[c+1]>heap[c]{c++};if heap[c]<=value{break};heap[p]=heap[c];p=c};heap[p]=value;return result }
fn push_min(mut heap [64]i32, mut count int, value i32) { mut p:=count;count++;for p>0&&heap[(p-1)/2]>value{q:=(p-1)/2;heap[p]=heap[q];p=q};heap[p]=value }
fn pop_min(mut heap [64]i32, mut count int) i32 { result:=heap[0];count--;value:=heap[count];if count==0{return result};mut p:=0;for 2*p+1<count{mut c:=2*p+1;if c+1<count&&heap[c+1]<heap[c]{c++};if heap[c]>=value{break};heap[p]=heap[c];p=c};heap[p]=value;return result }

@[export: 'median_heap']
pub fn median_heap(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	unsafe {
		op_value:=input[0]
		if op_value<0||op_value>max_operations||length!=usize(1+2*op_value){return -1}
		count:=int(op_value);mut lower:=[64]i32{};mut upper:=[64]i32{};mut lc:=0;mut uc:=0;mut results:=[256]i64{}
		for i in 0..count{op,arg:=input[1+2*i],input[2+2*i]
			if op==0{if arg < -2147483648||arg>2147483647||lc+uc>=max_live_values{return -1};x:=i32(arg)
				if lc==0{push_max(mut lower,mut lc,x)}else if x<lower[0]{push_max(mut lower,mut lc,x);if lc-uc>1{push_min(mut upper,mut uc,pop_max(mut lower,mut lc))}}else{push_min(mut upper,mut uc,x);if lc<uc{push_max(mut lower,mut lc,pop_min(mut upper,mut uc))}};results[i]=nil_sentinel
			}else if op>=1&&op<=4{if arg!=0{return -1};if op==1{results[i]=if lc>0{i64(lower[0])}else{nil_sentinel}}else if op==2{if lc==0{results[i]=nil_sentinel}else{results[i]=i64(pop_max(mut lower,mut lc));if lc<uc{push_max(mut lower,mut lc,pop_min(mut upper,mut uc))}}}else if op==3{results[i]=i64(lc+uc)}else{results[i]=if lc==0{1}else{0}}}else{return -1}
		}
		output_bytes:=count*8;if unsafe { output == nil }||capacity<usize(output_bytes){return -2};for i in 0..count{store_i64_le(mut output,8*i,results[i])};return i64(output_bytes)
	}
}
