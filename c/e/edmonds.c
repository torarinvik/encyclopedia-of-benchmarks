#include <stdint.h>
#include <stddef.h>
#define NMAX 5
#define EMAX 12
#define IMAX 1000000000
struct Edge { int u,v,w; };
int64_t edmonds(const int64_t *a, size_t len) {
 if (!a || len<3 || len>39) return -1;
 int n=(int)a[0], root=(int)a[1], m=(int)a[2];
 if (n<1||n>NMAX||root<0||root>=n||m<0||m>EMAX||len!=(size_t)(3+3*m)) return -1;
 struct Edge e[EMAX], ne[EMAX];
 for(int i=0;i<m;i++){int64_t u=a[3+3*i],v=a[4+3*i],w=a[5+3*i]; if(u<0||u>=n||v<0||v>=n||w<0||w>100)return -1; e[i]=(struct Edge){(int)u,(int)v,(int)w};}
 long long answer=0;
 for(;;){
  int in[NMAX],pre[NMAX]; for(int i=0;i<n;i++){in[i]=IMAX;pre[i]=-1;}
  for(int i=0;i<m;i++) if(e[i].u!=e[i].v && e[i].v!=root && e[i].w<in[e[i].v]){in[e[i].v]=e[i].w;pre[e[i].v]=e[i].u;}
  in[root]=0; for(int i=0;i<n;i++) if(in[i]==IMAX)return -1;
  int id[NMAX],vis[NMAX]; for(int i=0;i<n;i++){id[i]=-1;vis[i]=-1;}
  int cycles=0;
  for(int i=0;i<n;i++){answer+=in[i]; int v=i; while(vis[v]!=i&&id[v]==-1&&v!=root){vis[v]=i;v=pre[v];} if(v!=root&&id[v]==-1){for(int u=pre[v];u!=v;u=pre[u])id[u]=cycles;id[v]=cycles++;}}
  if(cycles==0) return answer;
  int cycle_member[NMAX]; for(int i=0;i<n;i++) cycle_member[i]=(id[i]>=0);
  for(int i=0;i<n;i++) if(id[i]==-1) id[i]=cycles++;
  for(int i=0;i<m;i++){int u=id[e[i].u],v=id[e[i].v],w=e[i].w;if(u!=v)w-=in[e[i].v];ne[i]=(struct Edge){u,v,w};}
  root=id[root];n=cycles;for(int i=0;i<m;i++)e[i]=ne[i];
 }
}
