module minimum_element_of_array;
fn uint next_rng(uint* state){uint x=*state;x^=x<<13;x^=x>>17;x^=x<<5;*state=x==0?0x9e3779b9:x;return *state;}
fn usz part(long[128]* a,usz lo,usz hi){long pivot=a[hi];usz i=lo;for(usz j=lo;j<hi;j++)if(a[j]<=pivot){long t=a[i];a[i]=a[j];a[j]=t;i++;}long t=a[i];a[i]=a[hi];a[hi]=t;return i;}
fn long select_k(long[128]* a,usz lo,usz hi,usz k,uint* state){if(lo==hi)return a[lo];usz p=lo+(usz)(next_rng(state)%(uint)(hi-lo+1));long t=a[p];a[p]=a[hi];a[hi]=t;p=part(a,lo,hi);usz rank=p-lo+1;if(k==rank)return a[p];if(k<rank)return select_k(a,lo,p-1,k,state);return select_k(a,p+1,hi,k-rank,state);}
fn long minimum_element_of_array(long* values,usz length) @export("minimum_element_of_array"){
 if(values==null||length<4)return -1;long n=values[0];long k=values[1];long seed=values[2];if(n<1||n>128||length!=(usz)n+3||k<1||k>n||seed<0||seed>2147483647)return -1;
 long[128] a;for(usz i=0;i<(usz)n;i++){a[i]=values[i+3];if(a[i]<-1000000||a[i]>1000000)return -1;for(usz j=0;j<i;j++)if(a[i]==a[j])return -1;}
 uint state=seed==0?0x9e3779b9:(uint)seed;return select_k(&a,0,(usz)n-1,(usz)k,&state);
}
