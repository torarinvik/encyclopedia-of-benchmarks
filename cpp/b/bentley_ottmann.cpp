#include <array>
#include <cstddef>
#include <cstdint>
#include <algorithm>

namespace {
constexpr int N=24, E=2*N+N*(N-1)/2, P=N*(N-1)/2;
struct S { std::int64_t x1,y1,x2,y2; };
struct Ev { std::int64_t x,y; int a,b,t; bool done; };
std::int64_t cross(std::int64_t ax,std::int64_t ay,std::int64_t bx,std::int64_t by){return ax*by-ay*bx;}
bool intersect(const S&a,const S&b,std::int64_t&x,std::int64_t&y){auto rx=a.x2-a.x1,ry=a.y2-a.y1,sx=b.x2-b.x1,sy=b.y2-b.y1;auto d=cross(rx,ry,sx,sy);if(!d)return false;auto qx=b.x1-a.x1,qy=b.y1-a.y1,t=cross(qx,qy,sx,sy),u=cross(qx,qy,rx,ry);if(d<0){d=-d;t=-t;u=-u;}if(t<=0||t>=d||u<=0||u>=d)return false;auto xn=a.x1*d+t*rx,yn=a.y1*d+t*ry;if(xn%d||yn%d)return false;x=xn/d;y=yn/d;return true;}
bool less(const std::array<S,N>&s,int a,int b,std::int64_t x){auto da=s[a].x2-s[a].x1,db=s[b].x2-s[b].x1;auto na=s[a].y1*da+(x-s[a].x1)*(s[a].y2-s[a].y1),nb=s[b].y1*db+(x-s[b].x1)*(s[b].y2-s[b].y1),c=na*db-nb*da;if(c)return c<0;auto sl=(s[a].y2-s[a].y1)*db-(s[b].y2-s[b].y1)*da;return sl?sl<0:a<b;}
void put(std::uint8_t*out,std::size_t slot,std::int64_t v){auto b=static_cast<std::uint64_t>(v);for(int i=0;i<8;++i)out[slot*8+i]=static_cast<std::uint8_t>(b>>(8*i));}
}
extern "C" std::int64_t bentley_ottmann(const std::int64_t* in,std::size_t len,std::uint8_t*out,std::size_t cap){
 if(!in||len<1||in[0]<0||in[0]>N)return -1;int n=static_cast<int>(in[0]);if(len!=1+4*n)return -1;std::array<S,N>s{};
 for(int i=0;i<n;++i){auto x1=in[1+4*i],y1=in[2+4*i],x2=in[3+4*i],y2=in[4+4*i];if(x1< -1000||x1>1000||x2< -1000||x2>1000||y1< -1000||y1>1000||y2< -1000||y2>1000||x1==x2)return -1;s[i]=x1<x2?S{x1,y1,x2,y2}:S{x2,y2,x1,y1};}
 std::array<Ev,E>ev{};int ec=0;for(int i=0;i<n;++i){ev[ec++]={s[i].x1,s[i].y1,i,-1,0,false};ev[ec++]={s[i].x2,s[i].y2,i,-1,1,false};}bool scheduled[N][N]{};int active[N]{},ac=0;std::array<std::array<std::int64_t,2>,P>pts{};int pc=0;
 for(;;){int ei=ec;for(int j=0;j<ec;++j)if(!ev[j].done&&(ei==ec||ev[j].x<ev[ei].x||(ev[j].x==ev[ei].x&&ev[j].y<ev[ei].y)))ei=j;if(ei==ec)break;auto e=ev[ei];ev[ei].done=true;if(e.t==0)active[ac++]=e.a;else if(e.t==1){for(int j=0;j<ac;++j)if(active[j]==e.a){for(int k=j+1;k<ac;++k)active[k-1]=active[k];--ac;break;}}else pts[pc++]={e.x,e.y};
  for(int i=1;i<ac;++i){int v=active[i],j=i;while(j>0&&less(s,v,active[j-1],e.x)){active[j]=active[j-1];--j;}active[j]=v;}
  for(int i=1;i<ac;++i){int a=active[i-1],b=active[i];if(scheduled[a][b])continue;std::int64_t x,y;if(intersect(s[a],s[b],x,y)&&x>e.x){if(ec>=E)return -1;ev[ec++]={x,y,a,b,2,false};scheduled[a][b]=scheduled[b][a]=true;}}
 }
 std::sort(pts.begin(),pts.begin()+pc,[](auto a,auto b){return a[0]<b[0]||(a[0]==b[0]&&a[1]<b[1]);});auto bytes=static_cast<std::size_t>(1+2*pc)*8;if(!out||cap<bytes)return -2;put(out,0,pc);for(int i=0;i<pc;++i){put(out,1+2*i,pts[i][0]);put(out,2+2*i,pts[i][1]);}return static_cast<std::int64_t>(bytes);
}
