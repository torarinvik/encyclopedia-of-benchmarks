module median_of_running_array_integer;
fn void heap_push(long[256]* h,usz* count,bool is_max,long x){usz i=*count;(*count)++;h[i]=x;while(i>0){usz p=(i-1)/2;bool bad=is_max?h[p]<h[i]:h[p]>h[i];if(!bad)break;long t=h[p];h[p]=h[i];h[i]=t;i=p;}}
fn long heap_pop(long[256]*h,usz*count,bool is_max){long x=h[0];(*count)--;h[0]=h[*count];usz i=0;while(true){usz l=2*i+1;usz r=l+1;usz b=i;if(l<*count&&(is_max?h[l]>h[b]:h[l]<h[b]))b=l;if(r<*count&&(is_max?h[r]>h[b]:h[r]<h[b]))b=r;if(b==i)break;long t=h[i];h[i]=h[b];h[b]=t;i=b;}return x;}
fn void store(long x,char*o,usz p){ulong u=(ulong)x;for(usz b=0;b<8;b++)o[p+b]=(char)((u>>(8*b))&255);}
fn long median_of_running_array_integer(long*input,usz length,char*output,usz capacity) @export("median_of_running_array_integer"){
 if(input==null||length<2)return -1;long n0=input[0];if(n0<1||n0>256||length!=(usz)n0+1)return -1;usz n=(usz)n0;for(usz i=0;i<n;i++)if(input[i+1]<-1000000||input[i+1]>1000000)return -1;if(output==null||capacity<n*8)return -2;
 long[256] lo;long[256] hi;usz nl=0;usz nh=0;for(usz i=0;i<n;i++){long x=input[i+1];if(nh>0&&x<hi[0])heap_push(&lo,&nl,true,x);else heap_push(&hi,&nh,false,x);if(nl>nh+1)heap_push(&hi,&nh,false,heap_pop(&lo,&nl,true));else if(nh>nl+1)heap_push(&lo,&nl,true,heap_pop(&hi,&nh,false));long med=nl==nh?(lo[0]+hi[0])/2:(nl>nh?lo[0]:hi[0]);store(med,output,i*8);}return (long)(n*8);
}
