/// Run a linked FIFO trace, then drain the remaining nodes.
fn put_i32(out:&mut [u8],index:usize,value:i32){out[index*4..index*4+4].copy_from_slice(&value.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn linked_queue_fifo_trace(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<1{return -1}let x=std::slice::from_raw_parts(input,length);let n=x[0];if !(0..=127).contains(&n)||length!=1+2*n as usize{return -1}let n=n as usize;let mut values=[0i32;127];let mut next=[-1i32;127];let mut result=[0i32;127];let(mut head,mut rear)=(-1i32,-1i32);let(mut nodes,mut count)=(0usize,0usize);let mut closed=false;
 for i in 0..n{let op=x[1+2*i];let v=x[2+2*i];if op==0{if closed||v<i32::MIN as i64||v>i32::MAX as i64||nodes>=127{return -1}let node=nodes as i32;nodes+=1;values[node as usize]=v as i32;next[node as usize]=-1;if head<0{head=node}else{next[rear as usize]=node}rear=node;}else if op==1{if v!=0||head<0{return -1}result[count]=values[head as usize];count+=1;head=next[head as usize];if head<0{rear=-1;closed=true;}}else{return -1}}
 while head>=0{result[count]=values[head as usize];count+=1;head=next[head as usize]}let bytes=count*4;if bytes>0&&(output.is_null()||capacity<bytes){return -2}if bytes==0{return 0}let out=std::slice::from_raw_parts_mut(output,bytes);for i in 0..count{put_i32(out,i,result[i])}(bytes as i64)
}
