#include <stddef.h>
#include <stdint.h>
#define OPS 256
#define ITEMS 128
static uint64_t hv(uint64_t h,int64_t v){uint64_t x=(uint64_t)v;for(int i=0;i<8;i++)h=(h^((x>>(8*i))&255))*UINT64_C(0x100000001b3);return h;}
int64_t generic_heap(const int64_t*a,size_t n){if(!a||n<1||n>1+3*OPS||a[0]<0||a[0]>OPS||n!=1+3*(size_t)a[0])return -1;int64_t id[ITEMS],p[ITEMS];int pos[4096];for(int i=0;i<4096;i++)pos[i]=-1;int z=0;uint64_t h=UINT64_C(0xcbf29ce484222325);
#define SW(i,j) do{int t=id[i];id[i]=id[j];id[j]=t;t=(int)p[i];p[i]=p[j];p[j]=t;pos[id[i]]=i;pos[id[j]]=j;}while(0)
 for(int k=0;k<a[0];k++){int64_t op=a[1+3*k],x=a[2+3*k],v=a[3+3*k];if(op==0){if(x<0||x>=4096||v<INT32_MIN||v>INT32_MAX||pos[x]>=0||z>=ITEMS)return -1;int i=z++;id[i]=x;p[i]=v;pos[x]=i;while(i>0){int q=(i-1)/2;if(p[i]<=p[q])break;SW(i,q);i=q;}}
 else if(op==1||op==2){if(x||v||z==0)return -1;int64_t ri=id[0],rv=p[0];if(op==2){SW(0,z-1);z--;pos[ri]=-1;int i=0;while(2*i+1<z){int c=2*i+1;if(c+1<z&&p[c+1]>p[c])c++;if(p[i]>=p[c])break;SW(i,c);i=c;}}h=hv(h,ri);h=hv(h,rv);}
 else if(op==3){if(x<0||x>=4096||v<INT32_MIN||v>INT32_MAX||pos[x]<0)return -1;int i=pos[x];p[i]=v;while(i>0){int q=(i-1)/2;if(p[i]<=p[q])break;SW(i,q);i=q;}}
 else if(op==4||op==5){if(x||v)return -1;h=hv(h,op==4?z:(z==0));}else return -1;}
 return (int64_t)h;}
