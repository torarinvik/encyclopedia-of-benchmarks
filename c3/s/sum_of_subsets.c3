module sum_of_subsets;
fn void visit(long* nums, usz n, long target, usz start, long current, long remaining, long* path, usz depth, long* solutions, usz* lens, usz* count) {
 if(current>target||remaining+current<target)return;
 if(current==target){usz k=*count;lens[k]=depth;for(usz j=0;j<depth;j++)solutions[k*10+j]=path[j];*count+=1;return;}
 for(usz i=start;i<n;i++){path[depth]=nums[i];visit(nums,n,target,i+1,current+nums[i],remaining-nums[i],path,depth+1,solutions,lens,count);}
}
fn void put64(char* out, usz* pos, long x){ulong v=(ulong)x;for(usz j=0;j<8;j++){out[*pos]=(char)(v&255);*pos+=1;v>>=8;}}
fn long sum_of_subsets(long* input, usz length, char* output, usz capacity) @export("sum_of_subsets") {
 if(input==null||length<2)return -1;long n0=input[0],target=input[1];if(n0<0||n0>10||length!=(usz)n0+2||target<0||target>250)return -1;usz n=(usz)n0;long nums[10];long rem=0;for(usz i=0;i<n;i++){long x=input[2+i];if(x<0||x>50)return -1;nums[i]=x;rem+=x;}
 long path[10];long solutions[10240];usz lens[1024];usz count=0;visit(&nums[0],n,target,0,0,rem,&path[0],0,&solutions[0],&lens[0],&count);usz need=8;for(usz i=0;i<count;i++)need+=8+8*lens[i];if(output==null||capacity<need)return -2;usz pos=0;put64(output,&pos,(long)count);for(usz i=0;i<count;i++){put64(output,&pos,(long)lens[i]);for(usz j=0;j<lens[i];j++)put64(output,&pos,solutions[i*10+j]);}return (long)pos;
}
