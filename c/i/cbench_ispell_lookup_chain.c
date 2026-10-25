#include <stddef.h>
#include <stdint.h>

#define M 8
#define E 8
#define W 8
#define Q 8

static uint32_t ihash(const int64_t *a, size_t n, size_t mod) {
    uint32_t h=0; size_t i, first=n<4?n:4;
    for(i=0;i<first;i++) h=(h<<8)|(uint32_t)(a[i]-32);
    for(;i<n;i++) h=(h<<5)|(h>>27), h^=(uint32_t)(a[i]-32);
    return h%(uint32_t)mod;
}

int64_t cbench_ispell_lookup_chain(const int64_t *a,size_t len) {
    int64_t heads[M],next[E],lens[E]; size_t off[E],n,m,q,p,head0,next0,lens0,word0,i,b;
    uint8_t seen[E]={0}; size_t seen_count=0;
    if(!a||len<3||len>108||a[0]<1||a[0]>M||a[1]<1||a[1]>Q||a[2]<0||a[2]>E)return -1;
    m=(size_t)a[0];q=(size_t)a[1];n=(size_t)a[2];
    if(len<3+q+m+2*n)return -1;
    head0=3+q;next0=head0+m;lens0=next0+n;word0=lens0+n;p=word0;
    for(i=0;i<q;i++)if(a[3+i]<97||a[3+i]>122)return -1;
    for(i=0;i<m;i++){heads[i]=a[head0+i];if(heads[i]<-1||heads[i]>=(int64_t)n)return -1;}
    for(i=0;i<n;i++){next[i]=a[next0+i];lens[i]=a[lens0+i];if(next[i]<-1||next[i]>=(int64_t)n||lens[i]<1||lens[i]>W||p+(size_t)lens[i]>len)return -1;off[i]=p;for(size_t j=0;j<(size_t)lens[i];j++)if(a[p+j]<97||a[p+j]>122)return -1;p+=(size_t)lens[i];}
    if(p!=len)return -1;
    for(b=0;b<m;b++)for(int64_t x=heads[b];x!=-1;x=next[x]){size_t j=(size_t)x;if(seen[j])return -1;seen[j]=1;seen_count++;if(ihash(a+off[j],(size_t)lens[j],m)!=b)return -1;}
    if(seen_count!=n)return -1;
    b=ihash(a+3,q,m);
    for(int64_t x=heads[b];x!=-1;x=next[x]){size_t j=(size_t)x;if((size_t)lens[j]==q){size_t k=0;while(k<q&&a[off[j]+k]==a[3+k])k++;if(k==q)return (int64_t)j+1;}}
    return 0;
}
