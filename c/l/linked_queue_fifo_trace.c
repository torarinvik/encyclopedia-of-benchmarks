/* Run a bounded linked-queue trace and emit explicit dequeues plus final drain. */
#include <stddef.h>
#include <stdint.h>
static void put_i32(uint8_t *out,size_t index,int32_t value){uint32_t bits=(uint32_t)value;for(size_t b=0;b<4;b++)out[index*4+b]=(uint8_t)(bits>>(8*b));}
int64_t linked_queue_fifo_trace(const int64_t *in,size_t len,uint8_t *out,size_t cap){
 if(!in||len<1)return -1;int64_t ops64=in[0];if(ops64<0||ops64>127||len!=(size_t)(1+2*ops64))return -1;size_t ops=(size_t)ops64;
 int32_t value[127],next[127],result[127];for(size_t i=0;i<127;i++)next[i]=-1;int head=-1,rear=-1;size_t nodes=0,count=0;int closed=0;
 for(size_t i=0;i<ops;i++){int64_t op=in[1+2*i],v=in[2+2*i];if(op==0){if(closed||v<INT32_MIN||v>INT32_MAX||nodes>=127)return -1;int node=(int)nodes++;value[node]=(int32_t)v;next[node]=-1;if(head<0)head=node;else next[rear]=node;rear=node;}else if(op==1){if(v!=0||head<0)return -1;result[count++]=value[head];head=next[head];if(head<0){rear=-1;closed=1;}}else return -1;}
 while(head>=0){result[count++]=value[head];head=next[head];}size_t bytes=count*4;if(bytes&&(!out||cap<bytes))return -2;for(size_t i=0;i<count;i++)put_i32(out,i,result[i]);return (int64_t)bytes;
}
