module linked_queue_fifo_trace;
fn void put_i32(long value,char* output,usz index){uint bits=@bitcast(uint)(value.i32());for(usz b=0;b<4;b++){output[index*4+b]=(char)(bits&255);bits>>=8;}}
fn long linked_queue_fifo_trace(long* input,usz length,char* output,usz capacity) @export("linked_queue_fifo_trace") {
 if(input==null||length<1)return -1;long count64=input[0];if(count64<0||count64>127||length!=(usz)(1+2*count64))return -1;usz ops=(usz)count64;long[127] values,next,result;for(usz i=0;i<127;i++)next[i]=-1;long head=-1,rear=-1;usz nodes=0,count=0;bool closed=false;
 for(usz i=0;i<ops;i++){long op=input[1+2*i],v=input[2+2*i];if(op==0){if(closed||v<(-2147483647l-1)||v>2147483647l||nodes>=127)return -1;long node=(long)nodes;nodes++;values[node]=v;next[node]=-1;if(head<0)head=node;else next[rear]=node;rear=node;}else if(op==1){if(v!=0||head<0)return -1;result[count++]=values[head];head=next[head];if(head<0){rear=-1;closed=true;}}else return -1;}
 while(head>=0){result[count++]=values[head];head=next[head];}usz bytes=count*4;if(bytes>0&&(output==null||capacity<bytes))return -2;for(usz i=0;i<count;i++)put_i32(result[i],output,i);return (long)bytes;
}
