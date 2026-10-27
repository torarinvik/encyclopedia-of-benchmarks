#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#define MAX_N 8
#define MAX_M 28
#define MAX_INPUT 59
static void put(uint8_t*o,size_t at,int64_t x){uint64_t b=(uint64_t)x;for(size_t i=0;i<8;++i){o[at+i]=(uint8_t)(b&255U);b>>=8;}}
static bool connected(size_t n,size_t m,const size_t*u,const size_t*v,const bool*on,int skip){bool seen[MAX_N]={0};size_t q[MAX_N],head=0,tail=1;q[0]=0;seen[0]=true;while(head<tail){size_t a=q[head++];for(size_t e=0;e<m;++e)if(on[e]&&(int)e!=skip){size_t b=MAX_N;if(u[e]==a)b=v[e];else if(v[e]==a)b=u[e];if(b<MAX_N&&!seen[b]){seen[b]=true;q[tail++]=b;}}}for(size_t i=0;i<n;++i)if(!seen[i])return false;return true;}
static bool edge_connected(size_t n,size_t m,const size_t*u,const size_t*v,const bool*on){if(!connected(n,m,u,v,on,-1))return false;for(size_t e=0;e<m;++e)if(on[e]&&!connected(n,m,u,v,on,(int)e))return false;return true;}
int64_t two_edge_connected_spanning_subgraph_greedy(const int64_t*in,size_t len,uint8_t*out,size_t cap){
 if(!in||len<2||len>MAX_INPUT)return -1;int64_t n0=in[0],m0=in[1];if(n0<3||n0>MAX_N||m0<3||m0>MAX_M||len!=2+2*(size_t)m0)return -1;size_t n=(size_t)n0,m=(size_t)m0,u[MAX_M],v[MAX_M];
 for(size_t i=0;i<m;++i){int64_t a=in[2+2*i],b=in[3+2*i];if(a<0||a>=b||b>=n)return -1;u[i]=(size_t)a;v[i]=(size_t)b;for(size_t j=0;j<i;++j)if(u[j]==u[i]&&v[j]==v[i])return -1;}
 bool on[MAX_M];for(size_t i=0;i<m;++i)on[i]=true;if(!edge_connected(n,m,u,v,on))return -1;
 for(size_t e=0;e<m;++e){on[e]=false;if(!edge_connected(n,m,u,v,on))on[e]=true;}
 size_t count=0;for(size_t e=0;e<m;++e)if(on[e])++count;size_t bytes=8*(1+2*count);if(!out||cap<bytes)return -2;put(out,0,(int64_t)count);size_t at=8;
 for(size_t a=0;a<n;++a)for(size_t b=a+1;b<n;++b)for(size_t e=0;e<m;++e)if(on[e]&&u[e]==a&&v[e]==b){put(out,at,(int64_t)a);put(out,at+8,(int64_t)b);at+=16;}
 return (int64_t)bytes;
}
