#include <cstddef>
#include <cstdint>
#define MAX_N 10
#define MAX_SOLUTIONS 1024
#define MAX_OUTPUT 90120
static void put64(std::uint8_t *out,std::size_t *p,std::int64_t x){std::uint64_t v=(std::uint64_t)x;for(std::size_t j=0;j<8;j++){out[(*p)++]=(std::uint8_t)v;v>>=8;}}
static void visit(const std::int64_t *nums,std::size_t n,std::int64_t target,std::size_t start,std::int64_t current,std::int64_t remaining,std::int64_t path[MAX_N],std::size_t depth,std::int64_t solutions[MAX_SOLUTIONS][MAX_N],std::size_t lens[MAX_SOLUTIONS],std::size_t *count){
 if(current>target||remaining+current<target)return;
 if(current==target){std::size_t k=*count;lens[k]=depth;for(std::size_t j=0;j<depth;j++)solutions[k][j]=path[j];(*count)++;return;}
 for(std::size_t i=start;i<n;i++){path[depth]=nums[i];visit(nums,n,target,i+1,current+nums[i],remaining-nums[i],path,depth+1,solutions,lens,count);}
}
extern "C" std::int64_t sum_of_subsets(const std::int64_t *input,std::size_t length,std::uint8_t *output,std::size_t capacity){
 if(input==NULL||length<2)return -1;std::int64_t nn=input[0],target=input[1];if(nn<0||nn>10||length!=(std::size_t)nn+2||target<0||target>250)return -1;std::size_t n=(std::size_t)nn;std::int64_t nums[MAX_N],remaining=0;for(std::size_t i=0;i<n;i++){std::int64_t x=input[2+i];if(x<0||x>50)return -1;nums[i]=x;remaining+=x;}
 std::int64_t solutions[MAX_SOLUTIONS][MAX_N];std::size_t lens[MAX_SOLUTIONS],count=0;std::int64_t path[MAX_N];visit(nums,n,target,0,0,remaining,path,0,solutions,lens,&count);std::size_t need=8;for(std::size_t i=0;i<count;i++)need+=8+8*lens[i];if(output==NULL||capacity<need)return -2;std::size_t pos=0;put64(output,&pos,(std::int64_t)count);for(std::size_t i=0;i<count;i++){put64(output,&pos,(std::int64_t)lens[i]);for(std::size_t j=0;j<lens[i];j++)put64(output,&pos,solutions[i][j]);}return (std::int64_t)pos;
}
