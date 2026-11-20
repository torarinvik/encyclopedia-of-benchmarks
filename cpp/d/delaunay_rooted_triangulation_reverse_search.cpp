// Delaunay-rooted reverse search over convex polygon triangulations.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kN=8, kD=20, kStates=132;
struct Point { std::int64_t x=0,y=0; };
struct Edge { int u=0,v=0; };
struct Context { int n=0,d=0; std::array<Point,kN> p{}; std::array<Edge,kD> diag{}; };
std::int64_t orient(Point a,Point b,Point c){return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);}
std::int64_t incircle(Point a,Point b,Point c,Point d){
 const auto ax=a.x-d.x,ay=a.y-d.y,bx=b.x-d.x,by=b.y-d.y,cx=c.x-d.x,cy=c.y-d.y;
 const auto al=ax*ax+ay*ay,bl=bx*bx+by*by,cl=cx*cx+cy*cy;
 return al*(bx*cy-by*cx)-bl*(ax*cy-ay*cx)+cl*(ax*by-ay*bx);
}
bool boundary(int n,int u,int v){return v==u+1||(u==0&&v==n-1);}
int edge_index(const Context& c,int u,int v){for(int i=0;i<c.d;i++)if(c.diag[i].u==u&&c.diag[i].v==v)return i;return -1;}
bool crosses(Edge a,Edge b){return (a.u<b.u&&b.u<a.v&&a.v<b.v)||(b.u<a.u&&a.u<b.v&&b.v<a.v);}
std::array<std::uint16_t,kN> adjacency(const Context& c,std::uint32_t mask){
 std::array<std::uint16_t,kN> rows{};
 for(int u=0;u<c.n;u++){int v=(u+1)%c.n;rows[u]|=std::uint16_t(1)<<v;rows[v]|=std::uint16_t(1)<<u;}
 for(int i=0;i<c.d;i++)if(mask&(std::uint32_t(1)<<i)){int u=c.diag[i].u,v=c.diag[i].v;rows[u]|=std::uint16_t(1)<<v;rows[v]|=std::uint16_t(1)<<u;}
 return rows;
}
int triangle_count(const Context& c,std::uint32_t mask){auto rows=adjacency(c,mask);int count=0;for(int a=0;a<c.n;a++)for(int b=a+1;b<c.n;b++)for(int z=b+1;z<c.n;z++)if((rows[a]&(1u<<b))&&(rows[b]&(1u<<z))&&(rows[a]&(1u<<z)))count++;return count;}
bool common_opposites(const Context& c,std::uint32_t mask,int edge,int& inside,int& outside){
 auto rows=adjacency(c,mask);const int u=c.diag[edge].u,v=c.diag[edge].v;const auto common=rows[u]&rows[v];int found=0;inside=outside=-1;
 for(int w=0;w<c.n;w++)if(common&(1u<<w)){if(u<w&&w<v)inside=w;else outside=w;found++;}
 return found==2&&inside>=0&&outside>=0;
}
bool flip(const Context& c,std::uint32_t mask,int edge,bool require_lawson,std::uint32_t& result){
 int in=-1,out=-1;if(!common_opposites(c,mask,edge,in,out))return false;
 if(require_lawson&&incircle(c.p[c.diag[edge].u],c.p[in],c.p[c.diag[edge].v],c.p[out])<=0)return false;
 int lo=in<out?in:out,hi=in<out?out:in;int opposite=edge_index(c,lo,hi);if(opposite<0)return false;
 result=(mask&~(std::uint32_t(1)<<edge))|(std::uint32_t(1)<<opposite);return true;
}
bool parent(const Context& c,std::uint32_t mask,std::uint32_t& result){for(int e=0;e<c.d;e++)if(mask&(std::uint32_t(1)<<e))if(flip(c,mask,e,true,result))return true;return false;}
bool valid_root(const Context& c,std::uint32_t mask){
 if(triangle_count(c,mask)!=c.n-2)return false;auto rows=adjacency(c,mask);
 for(int a=0;a<c.n;a++)for(int b=a+1;b<c.n;b++)for(int z=b+1;z<c.n;z++)if((rows[a]&(1u<<b))&&(rows[b]&(1u<<z))&&(rows[a]&(1u<<z)))for(int q=0;q<c.n;q++)if(q!=a&&q!=b&&q!=z&&incircle(c.p[a],c.p[b],c.p[z],c.p[q])>0)return false;
 return true;
}
int reverse_search(const Context& c,std::uint32_t root){
 std::array<std::uint32_t,kStates> states{};std::array<std::uint8_t,kStates> cursor{};int top=0,count=1;states[0]=root;
 while(top>=0){if(cursor[top]>=c.d){top--;continue;}int e=cursor[top]++;if(!(states[top]&(std::uint32_t(1)<<e)))continue;std::uint32_t child=0,par=0;if(!flip(c,states[top],e,false,child)||!parent(c,child,par)||par!=states[top])continue;if(count>=kStates)return -1;count++;states[++top]=child;cursor[top]=0;}
 return count;
}
} // namespace

extern "C" std::int64_t delaunay_rooted_triangulation_reverse_search(const std::int64_t* input,std::size_t length){
 if(input==nullptr||length<2||length>29)return -1;const auto n64=input[0];if(n64<3||n64>kN||length!=std::size_t(4*n64-4))return -1;
 Context c{};c.n=int(n64);for(int i=0;i<c.n;i++){c.p[i]={input[1+2*i],input[2+2*i]};if(c.p[i].x< -50||c.p[i].x>50||c.p[i].y< -50||c.p[i].y>50)return -1;}
 for(int a=0;a<c.n;a++)for(int b=a+1;b<c.n;b++)for(int z=b+1;z<c.n;z++)if(orient(c.p[a],c.p[b],c.p[z])<=0)return -1;
 for(int a=0;a<c.n;a++)for(int b=a+1;b<c.n;b++)for(int z=b+1;z<c.n;z++)for(int q=z+1;q<c.n;q++)if(incircle(c.p[a],c.p[b],c.p[z],c.p[q])==0)return -1;
 for(int u=0;u<c.n;u++)for(int v=u+1;v<c.n;v++)if(!boundary(c.n,u,v))c.diag[c.d++]={u,v};
 const std::size_t at=1+2*c.n;if(input[at]!=c.n-3)return -1;std::uint32_t root=0;Edge previous{-1,-1};
 for(int i=0;i<c.n-3;i++){auto u64=input[at+1+2*i],v64=input[at+2+2*i];if(u64<0||u64>=v64||v64>=c.n)return -1;Edge e{int(u64),int(v64)};if(boundary(c.n,e.u,e.v)||(i>0&&(e.u<previous.u||(e.u==previous.u&&e.v<=previous.v))))return -1;int ix=edge_index(c,e.u,e.v);if(ix<0)return -1;root|=std::uint32_t(1)<<ix;previous=e;}
 int seen=0;for(int i=0;i<c.d;i++)if(root&(std::uint32_t(1)<<i)){seen++;for(int j=i+1;j<c.d;j++)if((root&(std::uint32_t(1)<<j))&&crosses(c.diag[i],c.diag[j]))return -1;}
 if(seen!=c.n-3||!valid_root(c,root))return -1;return reverse_search(c,root);
}
