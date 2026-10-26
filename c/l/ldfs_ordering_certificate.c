/* Clean-room Lexicographic Depth-First Search with 4-vertex certificates. */
#include <stddef.h>
#include <stdint.h>
enum { MAX_N=8, MAX_INPUT=10, MAX_FIELDS=234 };
static void put(uint8_t *o,size_t at,int64_t x){uint64_t b=(uint64_t)x;for(size_t i=0;i<8;++i){o[at+i]=(uint8_t)b;b>>=8;}}
static int better(const uint64_t *adj,const int *order,size_t used,size_t x,size_t y){for(size_t k=used;k>0;--k){size_t u=(size_t)order[k-1];int xb=(int)((adj[x]>>u)&1u),yb=(int)((adj[y]>>u)&1u);if(xb!=yb)return xb>yb;}return x<y;}
int64_t ldfs_ordering_certificate(const int64_t *v,size_t n,uint8_t *out,size_t cap){
 if(!v||n<3||n>MAX_INPUT||v[0]<1||v[0]>MAX_N)return -1;size_t count=(size_t)v[0];if(n!=count+2||v[1]<0||v[1]>=(int64_t)count)return -1;uint64_t all=(UINT64_C(1)<<count)-1,adj[MAX_N]={0};
 for(size_t i=0;i<count;++i){if(v[2+i]<0||(uint64_t)v[2+i]>all||((uint64_t)v[2+i]&(UINT64_C(1)<<i)))return -1;adj[i]=(uint64_t)v[2+i];}for(size_t i=0;i<count;++i)for(size_t j=0;j<count;++j)if(((adj[i]>>j)&1u)!=((adj[j]>>i)&1u))return -1;
 uint64_t reach=UINT64_C(1)<<(size_t)v[1];for(size_t pass=0;pass<count;++pass){uint64_t old=reach;for(size_t i=0;i<count;++i)if((reach>>i)&1u)reach|=adj[i];if(old==reach)break;}if(reach!=all)return -1;
 int order[MAX_N];size_t used=1;order[0]=(int)v[1];uint64_t visited=UINT64_C(1)<<(size_t)v[1];while(used<count){size_t chosen=count;for(size_t x=0;x<count;++x)if(!((visited>>x)&1u)&&(chosen==count||better(adj,order,used,x,chosen)))chosen=x;order[used++]=(int)chosen;visited|=UINT64_C(1)<<chosen;}
 int64_t fields[MAX_FIELDS]={0};fields[0]=(int64_t)count;for(size_t i=0;i<count;++i)fields[1+i]=order[i];size_t certs=0,at=count+2;
 for(size_t i=0;i<count;++i)for(size_t j=i+1;j<count;++j)for(size_t k=j+1;k<count;++k){size_t a=(size_t)order[i],b=(size_t)order[j],c=(size_t)order[k];if(((adj[a]>>c)&1u)&&!((adj[a]>>b)&1u)){int64_t d=-1;for(size_t t=i+1;t<j;++t){size_t x=(size_t)order[t];if(((adj[x]>>b)&1u)&&!((adj[x]>>c)&1u)){d=(int64_t)x;break;}}fields[at++]=(int64_t)a;fields[at++]=(int64_t)b;fields[at++]=(int64_t)c;fields[at++]=d;++certs;}}
 fields[count+1]=(int64_t)certs;size_t bytes=8*at;if(!out||cap<bytes)return -2;for(size_t i=0;i<at;++i)put(out,8*i,fields[i]);return (int64_t)bytes;
}
