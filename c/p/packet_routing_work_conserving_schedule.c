#include <stddef.h>
#include <stdint.h>
#define N 8
#define M 12
#define P 8
#define HOPS 56
#define MAX_INPUT 99
static int parse(const int64_t*a,size_t len,int*n,int*m,int*p,int u[M],int v[M],int plen[P],int path[P][N]){
 if(!a||len<3||len>MAX_INPUT)return 0;int64_t n0=a[0],m0=a[1],p0=a[2];if(n0<2||n0>N||m0<1||m0>M||p0<1||p0>P)return 0;*n=(int)n0;*m=(int)m0;*p=(int)p0;size_t at=3;if(at+2*(size_t)*m>len)return 0;
 int seen[M][M]={{0}};
 for(int e=0;e<*m;e++){int64_t x=a[at++],y=a[at++];if(x<0||x>=*n||y<0||y>=*n||x==y)return 0;int lo=(int)(x<y?x:y),hi=(int)(x<y?y:x);if(seen[lo][hi])return 0;seen[lo][hi]=1;u[e]=(int)x;v[e]=(int)y;}
 for(int q=0;q<*p;q++){if(at+2>len)return 0;int64_t start=a[at++],k=a[at++];if(start<0||start>=*n||k<1||k>*n-1||at+(size_t)k>len)return 0;plen[q]=(int)k;int cur=(int)start;int used_vertex[N]={0},used_edge[M]={0};used_vertex[cur]=1;
  for(int j=0;j<plen[q];j++){int64_t e0=a[at++];if(e0<0||e0>=*m)return 0;int e=(int)e0;if(used_edge[e])return 0;used_edge[e]=1;path[q][j]=e;int next=-1;if(u[e]==cur)next=v[e];else if(v[e]==cur)next=u[e];else return 0;if(used_vertex[next])return 0;used_vertex[next]=1;cur=next;}}
 return at==len;
}
int64_t packet_routing_work_conserving_schedule(const int64_t*input,size_t length,uint8_t*output,size_t capacity){
 int n,m,p,u[M]={0},v[M]={0},plen[P]={0},path[P][N]={{0}};if(!parse(input,length,&n,&m,&p,u,v,plen,path))return -1;
 int pos[P]={0},tt[HOPS],te[HOPS],tp[HOPS],count=0,time=0;
 for(;;){int active=0,chosen[M];for(int e=0;e<m;e++)chosen[e]=-1;for(int q=0;q<p;q++)if(pos[q]<plen[q]){active=1;int e=path[q][pos[q]];if(chosen[e]<0)chosen[e]=q;}if(!active)break;
  for(int e=0;e<m;e++)if(chosen[e]>=0){if(count>=HOPS)return -1;tt[count]=time;te[count]=e;tp[count]=chosen[e];count++;pos[chosen[e]]++;}time++;if(time>N*P)return -1;
 }
 size_t bytes=(size_t)(2+3*count)*8;if(!output||capacity<bytes)return -2;int64_t words[2+3*HOPS];words[0]=time;words[1]=count;for(int i=0;i<count;i++){words[2+3*i]=tt[i];words[3+3*i]=te[i];words[4+3*i]=tp[i];}for(size_t i=0;i<2+3*(size_t)count;i++){uint64_t x=(uint64_t)words[i];for(int b=0;b<8;b++)output[i*8+b]=(uint8_t)(x>>(8*b));}return (int64_t)bytes;
}
