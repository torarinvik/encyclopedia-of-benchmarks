/* Exact chromatic number through independent-set inclusion-exclusion. */
#include <stddef.h>
#include <stdint.h>

int64_t exact_graph_coloring_inclusion_exclusion(const int64_t*x,size_t len,uint8_t*out,size_t cap){
 if(!x)return -2;if(len<2||len>44)return -1;int64_t nv=x[0],mv=x[1];
 if(nv<1||nv>7||mv<0||mv>21||len!=2+2*(size_t)mv)return -1;size_t n=(size_t)nv,m=(size_t)mv;
 uint8_t adj[7][7]={{0}};for(size_t e=0;e<m;e++){int64_t av=x[2+2*e],bv=x[3+2*e];if(av<0||bv<0||av>=nv||bv>=nv||av==bv)return -1;size_t a=(size_t)av,b=(size_t)bv;if(adj[a][b])return -1;adj[a][b]=adj[b][a]=1;}
 int64_t counts[128]={0};counts[0]=1;size_t limit=(size_t)1<<n;
 for(size_t mask=1;mask<limit;mask++){size_t bit=mask&(~mask+1),v=0;while(((size_t)1<<v)!=bit)v++;size_t rest=mask^bit,allowed=rest;for(size_t u=0;u<n;u++)if(adj[v][u])allowed&=~((size_t)1<<u);counts[mask]=counts[rest]+counts[allowed];}
 int64_t chi=nv;for(size_t k=1;k<=n;k++){int64_t sum=0;for(size_t mask=0;mask<limit;mask++){int64_t term=1,base=counts[mask]-1;for(size_t q=0;q<k;q++)term*=base;size_t bits=0;for(size_t b=mask;b;b&=b-1)bits++;sum+=((n-bits)%2==0)?term:-term;}if(sum>0){chi=(int64_t)k;break;}}
 if(cap<8||!out)return -2;uint64_t value=(uint64_t)chi;for(size_t i=0;i<8;i++)out[i]=(uint8_t)(value>>(8*i));return 8;
}
