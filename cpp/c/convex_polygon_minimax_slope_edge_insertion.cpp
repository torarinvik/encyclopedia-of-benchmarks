#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_N=4, MAX_LEN=14;
struct Point { std::int64_t x,y,z; };
struct Triangle { int a,b,c; };
struct Slope { std::int64_t num,den; };
std::int64_t orient(const Point p[MAX_N],int a,int b,int c){return (p[b].x-p[a].x)*(p[c].y-p[a].y)-(p[b].y-p[a].y)*(p[c].x-p[a].x);}
Slope slope(const Point p[MAX_N],Triangle t){const auto a=p[t.a],b=p[t.b],c=p[t.c];const auto dx1=b.x-a.x,dy1=b.y-a.y,dz1=b.z-a.z,dx2=c.x-a.x,dy2=c.y-a.y,dz2=c.z-a.z;const auto det=dx1*dy2-dx2*dy1,gx=dz1*dy2-dz2*dy1,gy=dx1*dz2-dz1*dx2;return {gx*gx+gy*gy,det*det};}
int cmp(Slope a,Slope b){const auto x=a.num*b.den,y=b.num*a.den;return (x>y)-(x<y);}
Slope maximum(const Point p[MAX_N],Triangle a,Triangle b){auto x=slope(p,a),y=slope(p,b);return cmp(x,y)>=0?x:y;}
bool anchor(const Point p[MAX_N],Triangle t,int q){const auto a=p[t.a],b=p[t.b],c=p[t.c];const auto dx1=b.x-a.x,dy1=b.y-a.y,dz1=b.z-a.z,dx2=c.x-a.x,dy2=c.y-a.y,dz2=c.z-a.z;const auto det=dx1*dy2-dx2*dy1,gx=dz1*dy2-dz2*dy1,gy=dx1*dz2-dz1*dx2;if(gx==0&&gy==0)return false;int v[3]={t.a,t.b,t.c},o[2],used=0;for(int x:v)if(x!=q)o[used++]=x;const std::int64_t sign=det>0?1:-1;const auto dx=-gx*sign,dy=-gy*sign;const auto ux=p[o[0]].x-p[q].x,uy=p[o[0]].y-p[q].y,vx=p[o[1]].x-p[q].x,vy=p[o[1]].y-p[q].y;const auto turn=ux*vy-uy*vx;const std::int64_t side=turn>0?1:-1;return side*(ux*dy-uy*dx)>=0&&side*(dx*vy-dy*vx)>=0;}
bool crosses(const Point p[MAX_N],int a,int b,int c,int d){return orient(p,a,b,c)*orient(p,a,b,d)<0&&orient(p,c,d,a)*orient(p,c,d,b)<0;}
std::int64_t volume6(const Point p[MAX_N]){const auto ax=p[1].x-p[0].x,ay=p[1].y-p[0].y,az=p[1].z-p[0].z,bx=p[2].x-p[0].x,by=p[2].y-p[0].y,bz=p[2].z-p[0].z,cx=p[3].x-p[0].x,cy=p[3].y-p[0].y,cz=p[3].z-p[0].z;return ax*(by*cz-bz*cy)-ay*(bx*cz-bz*cx)+az*(bx*cy-by*cx);}
int rank(const Point p[MAX_N],int n,Slope target){Slope all[4];int count=0;for(int a=0;a<n;a++)for(int b=a+1;b<n;b++)for(int c=b+1;c<n;c++)all[count++]=slope(p,{a,b,c});int distinct=0;for(int i=0;i<count;i++)if(cmp(all[i],target)<0){bool seen=false;for(int j=0;j<i;j++)if(cmp(all[j],all[i])==0)seen=true;if(!seen)distinct++;}return distinct+1;}
}
extern "C" std::int64_t convex_polygon_minimax_slope_edge_insertion(const std::int64_t* input,std::size_t length){
 if(input==nullptr||length<1||length>MAX_LEN)return -1;const auto n0=input[0];if(n0<3||n0>4)return -1;const int n=static_cast<int>(n0);if(length!=static_cast<std::size_t>(1+3*n))return -1;Point p[MAX_N]{};
 for(int i=0;i<n;i++){p[i]={input[1+3*i],input[2+3*i],input[3+3*i]};if(p[i].x < -8||p[i].x>8||p[i].y < -8||p[i].y>8||p[i].z < -8||p[i].z>8)return -1;}
 std::int64_t area=0;for(int i=0;i<n;i++){int j=(i+1)%n;area+=p[i].x*p[j].y-p[i].y*p[j].x;}if(area==0)return -1;const int sign=area>0?1:-1;
 for(int a=0;a<n;a++)for(int b=a+1;b<n;b++)for(int c=b+1;c<n;c++)if(orient(p,a,b,c)==0)return -1;
 for(int e=0;e<n;e++){int j=(e+1)%n;for(int k=0;k<n;k++)if(k!=e&&k!=j&&sign*orient(p,e,j,k)<=0)return -1;}if(n==4&&volume6(p)==0)return -1;
 Triangle fan[2]={{0,1,2},{0,2,3}};Slope worst=n==3?slope(p,fan[0]):maximum(p,fan[0],fan[1]);
 if(n==4){bool done=false;for(int ti=0;ti<2&&!done;ti++){auto t=fan[ti];if(cmp(slope(p,t),worst)!=0)continue;int v[3]={t.a,t.b,t.c};for(int k=0;k<3&&!done;k++){int q=v[k];if(!anchor(p,t,q))continue;int o[2],u=0,s=-1;for(int j=0;j<3;j++)if(j!=k)o[u++]=v[j];for(int j=0;j<4;j++)if(j!=v[0]&&j!=v[1]&&j!=v[2])s=j;if(!crosses(p,q,s,o[0],o[1]))continue;Slope candidate=maximum(p,{q,s,o[0]},{q,s,o[1]});if(cmp(candidate,worst)<0){worst=candidate;done=true;}}}}
 return rank(p,n,worst);
}
