package linked_queue_fifo_trace
import "core:c"
put_i32 :: proc "contextless"(output:[^]u8,index:usize,value:i32){bits:=transmute(u32)value;for b:=0;b<4;b+=1{output[index*4+b]=u8(bits>>u32(8*b))}}
@(export)
linked_queue_fifo_trace :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<1 do return -1
 count64:=input[0];if count64<0||count64>127||length!=usize(1+2*count64) do return -1
 operations:=usize(count64);values:[127]i32;next:[127]i64;result:[127]i32;for i:usize=0;i<127;i+=1{next[i]=-1}
 head,rear:i64=-1,-1;nodes,count:usize=0,0;closed:=false
 for i:usize=0;i<operations;i+=1{operation,value:=input[1+2*i],input[2+2*i];if operation==0{if closed||value < -2147483648||value>2147483647||nodes>=127 do return -1;node:=i64(nodes);values[nodes]=i32(value);next[nodes]=-1;if head<0{head=node}else{next[usize(rear)]=node};rear=node;nodes+=1}else if operation==1{if value!=0||head<0 do return -1;result[count]=values[usize(head)];count+=1;head=next[usize(head)];if head<0{rear=-1;closed=true}}else{return -1}}
 for head>=0{result[count]=values[usize(head)];count+=1;head=next[usize(head)]}
 bytes:=count*4;if bytes>0&&(output==nil||capacity<bytes) do return -2;for i:usize=0;i<count;i+=1{put_i32(output,i,result[i])};return i64(bytes)
}
