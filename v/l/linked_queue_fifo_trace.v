module linked_queue_fifo_trace
fn put_i32_le(mut output &u8, index int, value i32) { mut bits:=u32(value);for b in 0..4{unsafe{output[index*4+b]=u8(bits&255)};bits>>=8} }
@[export: 'linked_queue_fifo_trace']
pub fn linked_queue_fifo_trace(input &i64,length usize,mut output &u8,capacity usize) i64 {
 if unsafe{input==nil}||length<1{return -1};ops64:=input[0];if ops64<0||ops64>127||length!=usize(1+2*ops64){return -1};ops:=int(ops64)
 unsafe{mut values:=[127]i32{};mut next:=[127]int{};mut result:=[127]i32{};for i in 0..127{next[i]=-1};mut head:=-1;mut rear:=-1;mut nodes:=0;mut count:=0;mut closed:=false
 for i in 0..ops{operation:=input[1+2*i];value:=input[2+2*i];if operation==0{if closed||value < -2147483648||value>2147483647||nodes>=127{return -1};values[nodes]=i32(value);next[nodes]=-1;if head<0{head=nodes}else{next[rear]=nodes};rear=nodes;nodes++}else if operation==1{if value!=0||head<0{return -1};result[count]=values[head];count++;head=next[head];if head<0{rear=-1;closed=true}}else{return -1}}
 for head>=0{result[count]=values[head];count++;head=next[head]};bytes:=count*4;if bytes>0&&(output==nil||capacity<bytes){return -2};for i in 0..count{put_i32_le(mut output,i,result[i])};return i64(bytes)}
}
