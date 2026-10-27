#include <cstddef>
#include <cstdint>
namespace {
constexpr int N=6,M=10,MAX_INPUT=60;
struct Graph{int n,m,s,t,u[M]{},v[M]{},cap[M]{},degree[N]{},rot[N][N]{};};
bool parse(const std::int64_t*a,std::size_t len,Graph&g){
 if(!a||len<4||len>MAX_INPUT)return false;auto n=a[0],m=a[1],s=a[2],t=a[3];
 if(n<2||n>N||m<1||m>M||s<0||s>=n||t<0||t>=n||s==t)return false;
 g.n=(int)n;g.m=(int)m;g.s=(int)s;g.t=(int)t;if(len<(std::size_t)(4+3*g.m))return false;
 int pair[N][N]{};std::size_t at=4;
 for(int e=0;e<g.m;e++){auto u=a[at++],v=a[at++],c=a[at++];if(u<0||u>=n||v<0||v>=n||u==v||c<0||c>5||pair[u][v]||pair[v][u])return false;pair[u][v]=pair[v][u]=1;g.u[e]=(int)u;g.v[e]=(int)v;g.cap[e]=(int)c;}
 int occ[M][2]{},seen[N][M]{};
 for(int x=0;x<g.n;x++){if(at>=len)return false;auto d=a[at++];if(d<0||d>=g.n||at+(std::size_t)d>len)return false;g.degree[x]=(int)d;
  for(int j=0;j<g.degree[x];j++){auto e0=a[at++];if(e0<0||e0>=g.m)return false;int e=(int)e0;if(seen[x][e])return false;seen[x][e]=1;g.rot[x][j]=e;if(g.u[e]==x)occ[e][0]++;else if(g.v[e]==x)occ[e][1]++;else return false;}}
 if(at!=len)return false;for(int e=0;e<g.m;e++)if(occ[e][0]!=1||occ[e][1]!=1)return false;
 int vis[N]{},q[N],h=0,z=0;vis[g.s]=1;q[z++]=g.s;while(h<z){int x=q[h++];for(int e=0;e<g.m;e++){int y=g.u[e]==x?g.v[e]:(g.v[e]==x?g.u[e]:-1);if(y>=0&&!vis[y])vis[y]=1,q[z++]=y;}}for(int x=0;x<g.n;x++)if(!vis[x])return false;return true;
}
int rem(const Graph&g,const int f[M],int x,int e){return g.u[e]==x?g.cap[e]-f[e]:f[e];}
int other(const Graph&g,int x,int e){return g.u[e]==x?g.v[e]:g.u[e];}
void put(std::uint8_t*out,std::int64_t v){auto b=(std::uint64_t)v;for(int i=0;i<8;i++)out[i]=(std::uint8_t)(b>>(8*i));}
}
extern "C" std::int64_t st_planar_leftmost_augmenting_flow(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){
 Graph g;if(!parse(input,length,g))return -1;int f[M]{},total=0;
 for(;;){int vis[N]{},par[N],pe[N],pd[N],next[N]{};for(int x=0;x<g.n;x++)par[x]=pe[x]=-1;int st[N],top=0;vis[g.s]=1;st[top++]=g.s;
  while(top&&!vis[g.t]){int x=st[top-1];if(next[x]>=g.degree[x]){--top;continue;}int e=g.rot[x][next[x]++],y=other(g,x,e);if(rem(g,f,x,e)>0&&!vis[y]){vis[y]=1;par[y]=x;pe[y]=e;pd[y]=g.u[e]==x?1:-1;st[top++]=y;}}
  if(!vis[g.t])break;int d=1000000;for(int y=g.t;y!=g.s;y=par[y]){int r=rem(g,f,par[y],pe[y]);if(r<d)d=r;}for(int y=g.t;y!=g.s;y=par[y])f[pe[y]]+=pd[y]*d;total+=d;
 }
 if(!output||capacity<8)return -2;put(output,total);return 8;
}
