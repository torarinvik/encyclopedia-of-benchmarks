#include <stddef.h>
#include <stdint.h>

#define NMAX 8
#define KMAX 8
#define QMAX 8192
typedef struct { int n; int v[NMAX]; int64_t cost; } path;
static int less(path a,path b){ if(a.cost!=b.cost)return a.cost<b.cost; for(int i=0;i<a.n&&i<b.n;i++)if(a.v[i]!=b.v[i])return a.v[i]<b.v[i]; return a.n<b.n; }
static int same(path a,path b){ if(a.n!=b.n)return 0; for(int i=0;i<a.n;i++)if(a.v[i]!=b.v[i])return 0; return 1; }
static int prefix(path a,path b,int n){ if(a.n<n||b.n<n)return 0; for(int i=0;i<n;i++)if(a.v[i]!=b.v[i])return 0; return 1; }
static int contains(path p,int v){for(int i=0;i<p.n;i++)if(p.v[i]==v)return 1;return 0;}
static void push(path q[],int *count,path p){if(*count<QMAX)q[(*count)++]=p;}
static path popmin(path q[],int *count){int m=0;for(int i=1;i<*count;i++)if(less(q[i],q[m]))m=i;path p=q[m];q[m]=q[--*count];return p;}
static int shortest(int n,int src,int dst,int64_t w[NMAX][NMAX],uint8_t banv[NMAX],uint8_t bane[NMAX][NMAX],path *out){
 path q[QMAX];int count=0;path start={.n=1,.v={0},.cost=0};start.v[0]=src;push(q,&count,start);
 while(count){path p=popmin(q,&count);int u=p.v[p.n-1];if(u==dst){*out=p;return 1;}for(int v=0;v<n;v++)if(w[u][v]>=0&&!banv[v]&&!bane[u][v]&&!contains(p,v)){path t=p;t.v[t.n++]=v;t.cost+=w[u][v];push(q,&count,t);}}
 return 0;
}
static void put(uint8_t *o,size_t at,int64_t x){uint64_t u=(uint64_t)x;for(int i=0;i<8;i++)o[at+i]=(uint8_t)(u>>(8*i));}
int64_t yens_kshortest_paths(const int64_t *in,size_t len,uint8_t *out,size_t cap){
 if(!in||len<4||in[0]<1||in[0]>NMAX||in[1]<1||in[1]>KMAX||in[2]<0||in[2]>=in[0]||in[3]<0||in[3]>=in[0])return -1;
 int n=(int)in[0],k=(int)in[1],src=(int)in[2],dst=(int)in[3];if(len!=(size_t)(4+n*n))return -1;
 int64_t w[NMAX][NMAX];for(int i=0;i<n;i++)for(int j=0;j<n;j++){int64_t x=in[4+i*n+j];if(x < -1||x>1000)return -1;w[i][j]=x;}
 path accepted[KMAX],cand[QMAX];int ac=0,cc=0;uint8_t bv[NMAX]={0},be[NMAX][NMAX]={{0}};path first;if(shortest(n,src,dst,w,bv,be,&first))accepted[ac++]=first;
 while(ac<k&&ac){path prev=accepted[ac-1];for(int i=0;i<prev.n-1;i++){path root={.n=i+1,.cost=0};for(int j=0;j<=i;j++)root.v[j]=prev.v[j];for(int j=0;j<i;j++)root.cost+=w[root.v[j]][root.v[j+1]];for(int z=0;z<ac;z++)if(prefix(accepted[z],root,i+1)&&accepted[z].n>i+1)be[accepted[z].v[i]][accepted[z].v[i+1]]=1;for(int j=0;j<i;j++)bv[root.v[j]]=1;path spur;if(shortest(n,root.v[i],dst,w,bv,be,&spur)){path total=root;for(int j=1;j<spur.n;j++)total.v[total.n++]=spur.v[j];total.cost=root.cost+spur.cost;int found=0;for(int z=0;z<ac;z++)found|=same(total,accepted[z]);for(int z=0;z<cc;z++)found|=same(total,cand[z]);if(!found)push(cand,&cc,total);}for(int j=0;j<i;j++)bv[root.v[j]]=0;for(int z=0;z<ac;z++)if(prefix(accepted[z],root,i+1)&&accepted[z].n>i+1)be[accepted[z].v[i]][accepted[z].v[i+1]]=0;}
 if(!cc)break;accepted[ac++]=popmin(cand,&cc);}
 size_t bytes=8;for(int i=0;i<ac;i++)bytes+=(size_t)(accepted[i].n+2)*8;if(!out||cap<bytes)return -2;put(out,0,ac);size_t at=8;for(int i=0;i<ac;i++){put(out,at,accepted[i].n);at+=8;for(int j=0;j<accepted[i].n;j++){put(out,at,accepted[i].v[j]);at+=8;}put(out,at,accepted[i].cost);at+=8;}return (int64_t)bytes;
}
