#include <stddef.h>
#include <stdint.h>
#define MAX_N 10
#define MAX_SOLUTIONS 1024
#define MAX_OUTPUT 90120
static void put64(uint8_t *out,size_t *p,int64_t x){uint64_t v=(uint64_t)x;for(size_t j=0;j<8;j++){out[(*p)++]=(uint8_t)v;v>>=8;}}
static void visit(const int64_t *nums,size_t n,int64_t target,size_t start,int64_t current,int64_t remaining,int64_t path[MAX_N],size_t depth,int64_t solutions[MAX_SOLUTIONS][MAX_N],size_t lens[MAX_SOLUTIONS],size_t *count){
 if(current>target||remaining+current<target)return;
 if(current==target){size_t k=*count;lens[k]=depth;for(size_t j=0;j<depth;j++)solutions[k][j]=path[j];(*count)++;return;}
 for(size_t i=start;i<n;i++){path[depth]=nums[i];visit(nums,n,target,i+1,current+nums[i],remaining-nums[i],path,depth+1,solutions,lens,count);}
}
int64_t sum_of_subsets(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
 if(input==NULL||length<2)return -1;int64_t nn=input[0],target=input[1];if(nn<0||nn>10||length!=(size_t)nn+2||target<0||target>250)return -1;size_t n=(size_t)nn;int64_t nums[MAX_N],remaining=0;for(size_t i=0;i<n;i++){int64_t x=input[2+i];if(x<0||x>50)return -1;nums[i]=x;remaining+=x;}
 int64_t solutions[MAX_SOLUTIONS][MAX_N];size_t lens[MAX_SOLUTIONS],count=0;int64_t path[MAX_N];visit(nums,n,target,0,0,remaining,path,0,solutions,lens,&count);size_t need=8;for(size_t i=0;i<count;i++)need+=8+8*lens[i];if(output==NULL||capacity<need)return -2;size_t pos=0;put64(output,&pos,(int64_t)count);for(size_t i=0;i<count;i++){put64(output,&pos,(int64_t)lens[i]);for(size_t j=0;j<lens[i];j++)put64(output,&pos,solutions[i][j]);}return (int64_t)pos;
}
