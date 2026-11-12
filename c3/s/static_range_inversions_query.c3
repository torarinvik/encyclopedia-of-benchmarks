module static_range_inversions_query;

const usz MAX_N = 128;
const usz MAX_Q = 32;

struct Query { usz left; usz right; usz id; usz block; }

fn usz lower(long[MAX_N]* a, usz n, long x) {
    usz lo=0,hi=n;
    while(lo<hi){usz mid=lo+(hi-lo)/2;if(a[mid]<x)lo=mid+1;else hi=mid;}
    return lo;
}
fn long bit_sum(long[MAX_N+1]* bit, usz count) {
    long sum=0;while(count>0){sum+=bit[count];count-=count&(~count+1);}return sum;
}
fn void bit_add(long[MAX_N+1]* bit, usz rank, long delta) {
    usz i=rank+1;while(i<=MAX_N){bit[i]+=delta;i+=i&(~i+1);}
}
fn bool before(Query a, Query b) {
    if(a.block!=b.block)return a.block<b.block;
    if(a.right!=b.right)return (a.block&1)==1 ? a.right>b.right : a.right<b.right;
    return a.id<b.id;
}
fn void put64(uint8* out, usz at, long value) {
    uint64 bits=(uint64)value;for(usz b=0;b<8;b+=1)out[at+b]=(uint8)(bits>>(8*b));
}

fn long static_range_inversions_query(long* input, usz length, uint8* output, usz capacity)
    @export("static_range_inversions_query") {
    if(input==null||length<2||length>195)return -1;
    long n64=input[0],q64=input[1];if(n64<1||n64>128||q64<1||q64>32)return -1;
    usz n=(usz)n64,q=(usz)q64;if(length!=2+n+2*q)return -1;
    long[MAX_N] values,sorted;
    for(usz i=0;i<n;i+=1){values[i]=input[2+i];if(values[i]<0||values[i]>1000000000)return -1;sorted[i]=values[i];}
    for(usz i=1;i<n;i+=1){long x=sorted[i];usz j=i;while(j>0&&sorted[j-1]>x){sorted[j]=sorted[j-1];j-=1;}sorted[j]=x;}
    usz distinct=0;for(usz i=0;i<n;i+=1)if(distinct==0||sorted[i]!=sorted[distinct-1]){sorted[distinct]=sorted[i];distinct+=1;}
    usz[MAX_N] ranks;
    for(usz i=0;i<n;i+=1)ranks[i]=lower(&sorted,distinct,values[i]);
    usz block=1;while((block+1)*(block+1)<=n)block+=1;
    Query[MAX_Q] queries;usz off=2+n;
    for(usz k=0;k<q;k+=1){long l=input[off],r=input[off+1];off+=2;if(l<0||l>=r||r>n64)return -1;queries[k]={ (usz)l,(usz)r,k,(usz)l/block };}
    for(usz i=1;i<q;i+=1){Query x=queries[i];usz j=i;while(j>0&&before(x,queries[j-1])){queries[j]=queries[j-1];j-=1;}queries[j]=x;}
    long[MAX_N+1] bit=zeroed;long[MAX_Q] answers=zeroed;usz left=0,right=0,window=0;long inversions=0;
    for(usz qi=0;qi<q;qi+=1){Query z=queries[qi];
        while(left>z.left){left-=1;usz x=ranks[left];inversions+=bit_sum(&bit,x);bit_add(&bit,x,1);window+=1;}
        while(right<z.right){usz x=ranks[right];inversions+=(long)window-bit_sum(&bit,x+1);bit_add(&bit,x,1);window+=1;right+=1;}
        while(left<z.left){usz x=ranks[left];inversions-=bit_sum(&bit,x);bit_add(&bit,x,-1);window-=1;left+=1;}
        while(right>z.right){right-=1;usz x=ranks[right];inversions-=(long)window-bit_sum(&bit,x+1);bit_add(&bit,x,-1);window-=1;}
        answers[z.id]=inversions;
    }
    usz bytes=8*q;if(output==null||capacity<bytes)return -2;
    for(usz k=0;k<q;k+=1)put64(output,8*k,answers[k]);return (long)bytes;
}
