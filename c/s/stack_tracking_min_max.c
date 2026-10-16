#include <stddef.h>
#include <stdint.h>
static void put64(uint8_t*out,size_t*pos,int64_t x){uint64_t b=(uint64_t)x;for(size_t j=0;j<8;j++){out[(*pos)++]=(uint8_t)b;b>>=8;}}
int64_t stack_tracking_min_max(const int64_t*input,size_t length,uint8_t*output,size_t output_capacity){
 if(input==NULL||length<2||length>130)return -1;int64_t max_size=input[0],op_count=input[1];if(max_size<0||max_size>64||op_count<0||op_count>64)return -1;size_t p=2;
 for(int64_t i=0;i<op_count;i++){if(p>=length)return -1;int64_t op=input[p++];if(op==1){if(p>=length||input[p]<INT32_MIN||input[p]>INT32_MAX)return -1;p++;}else if(op<2||op>5)return -1;}if(p!=length)return -1;
 int64_t values[64],mins[64],maxs[64],records[64][3];size_t top=0,record_count=0;p=2;
 for(int64_t i=0;i<op_count;i++){int64_t op=input[p++],tag=0,result=0;if(op==1){int64_t x=input[p++];if(top==(size_t)max_size){records[record_count][0]=1;records[record_count][1]=4;records[record_count][2]=1;record_count++;break;}values[top]=x;mins[top]=top? (mins[top-1]<x?mins[top-1]:x):x;maxs[top]=top?(maxs[top-1]>x?maxs[top-1]:x):x;top++;tag=1;result=1;}else if(op==2){if(top){result=values[--top];}else tag=3;}else if(op==3){if(top)result=mins[top-1];else tag=3;}else if(op==4){if(top)result=maxs[top-1];else tag=3;}else{tag=1;result=top?1:0;}records[record_count][0]=op;records[record_count][1]=tag;records[record_count][2]=result;record_count++;}
 size_t need=record_count*24;if(output==NULL||output_capacity<need)return -2;size_t pos=0;for(size_t i=0;i<record_count;i++)for(size_t j=0;j<3;j++)put64(output,&pos,records[i][j]);return (int64_t)pos;
}
