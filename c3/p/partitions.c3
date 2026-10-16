module partitions;
const long MAX_N=100;
const usz STRIDE=101;
fn long count_parts(usz n,usz k,long* memo){if((n==0&&k==0)||(n>0&&k==1)||n==k)return 1;if(k==0||k>n)return 0;usz idx=n*STRIDE+k;if(memo[idx]>=0)return memo[idx];memo[idx]=count_parts(n-1,k-1,memo)+count_parts(n-k,k,memo);return memo[idx];}
fn long partitions(long n) @export("partitions"){if(n<0||n>MAX_N)return -9223372036854775807-1;long[10201] memo;for(usz i=0;i<10201;i++)memo[i]=-1;long total=0;for(usz k=1;k<=(usz)n;k++)total+=count_parts((usz)n,k,&memo[0]);if(n==0)return 1;return total;}
