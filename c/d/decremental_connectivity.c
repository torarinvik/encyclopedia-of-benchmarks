#include <stddef.h>
#include <stdint.h>
#define MAX_N 32
#define MAX_Q 128
static int find(int *p,int x){while(p[x]!=x){p[x]=p[p[x]];x=p[x];}return x;}
static size_t side(uint64_t *adj,int n,int start,int block_u,int block_v,int *out){
 int seen[MAX_N]={0},stack[MAX_N*MAX_N],top=0;size_t count=0;stack[top++]=start;
 while(top){int u=stack[--top];if(seen[u])continue;seen[u]=1;out[count++]=u;for(int v=0;v<n;v++)if((adj[u]>>v)&1){if((u==block_u&&v==block_v)||(u==block_v&&v==block_u))continue;if(!seen[v])stack[top++]=v;}}
 return count;
}
int64_t decremental_connectivity(const int64_t *a,size_t len){
 if(!a||len<3||len>3+2*(MAX_N-1)+3*MAX_Q)return -1;
 int64_t nn=a[0],mm=a[1];if(nn<1||nn>MAX_N||mm<0||mm>=nn)return -1;int n=(int)nn,m=(int)mm;size_t ep=2+2*(size_t)m;if(len<=ep)return -1;int64_t qq=a[ep];if(qq<0||qq>MAX_Q||len!=ep+1+3*(size_t)qq)return -1;int q=(int)qq;
 uint64_t adj[MAX_N]={0};int parent[MAX_N];for(int i=0;i<n;i++)parent[i]=i;
 for(int i=0;i<m;i++){int64_t u0=a[2+2*i],v0=a[3+2*i];if(u0<0||u0>=n||v0<0||v0>=n||u0==v0)return -1;int u=(int)u0,v=(int)v0;if((adj[u]>>v)&1)return -1;int x=find(parent,u),y=find(parent,v);if(x==y)return -1;parent[y]=x;adj[u]|=UINT64_C(1)<<v;adj[v]|=UINT64_C(1)<<u;}
 int comp[MAX_N],next=0,stack[MAX_N*MAX_N];for(int i=0;i<n;i++)comp[i]=-1;
 for(int s=0;s<n;s++)if(comp[s]<0){int top=0;stack[top++]=s;comp[s]=next;while(top){int u=stack[--top];for(int v=0;v<n;v++)if(((adj[u]>>v)&1)&&comp[v]<0){comp[v]=next;stack[top++]=v;}}next++;}
 uint64_t h=UINT64_C(14695981039346656037);
 for(int k=0;k<q;k++){size_t p=ep+1+3*(size_t)k;int64_t op=a[p],u0=a[p+1],v0=a[p+2];if((op!=0&&op!=1)||u0<0||u0>=n||v0<0||v0>=n)return -1;int u=(int)u0,v=(int)v0;
  if(op==1){h^=(uint64_t)(comp[u]==comp[v]);h*=UINT64_C(1099511628211);continue;}
  if(!((adj[u]>>v)&1)||comp[u]!=comp[v])return -1;adj[u]&=~(UINT64_C(1)<<v);adj[v]&=~(UINT64_C(1)<<u);
  int left[MAX_N],right[MAX_N];size_t lc=side(adj,n,u,-1,-1,left),rc=side(adj,n,v,-1,-1,right);int *small;size_t sc;if(lc<rc||(lc==rc&&u<v)){small=left;sc=lc;}else{small=right;sc=rc;}for(size_t j=0;j<sc;j++)comp[small[j]]=next;next++;
 }
 return (int64_t)h;
}
