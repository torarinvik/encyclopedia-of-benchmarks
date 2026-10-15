/// Run a linked FIFO trace and return all removed values in little-endian i32.
fn putI32(out:[*]u8,index:usize,value:i32)void{const bits:u32=@bitCast(value);for(0..4)|b|out[index*4+b]=@truncate(bits>>@intCast(8*b));}
pub export fn linked_queue_fifo_trace(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length<1)return -1;const n64=input[0];if(n64<0 or n64>127)return -1;const n:usize=@intCast(n64);if(length!=1+2*n)return -1;var values:[127]i32=@splat(0);var next:[127]i32=@splat(-1);var result:[127]i32=@splat(0);var head:i32=-1;var rear:i32=-1;var nodes:usize=0;var count:usize=0;var closed=false;
 for(0..n)|i|{const op=input[1+2*i];const value=input[2+2*i];if(op==0){if(closed or value<std.math.minInt(i32) or value>std.math.maxInt(i32) or nodes>=127)return -1;const node:i32=@intCast(nodes);nodes+=1;values[@intCast(node)]=@intCast(value);next[@intCast(node)]=-1;if(head<0){head=node;}else{next[@intCast(rear)]=node;}rear=node;}else if(op==1){if(value!=0 or head<0)return -1;result[count]=values[@intCast(head)];count+=1;head=next[@intCast(head)];if(head<0){rear=-1;closed=true;}}else{return -1;}}
 while(head>=0){result[count]=values[@intCast(head)];count+=1;head=next[@intCast(head)];}const bytes=count*4;if(bytes>0 and (output==null or capacity<bytes))return -2;for(0..count)|i|putI32(output,i,result[i]);return @intCast(bytes);
}
