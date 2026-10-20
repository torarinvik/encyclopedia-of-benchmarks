#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>

namespace {
constexpr int N=8, A=15, V=32, O=1024;
constexpr double EPS=1e-10;
struct Point{double x,y;}; struct Arc{int site,prev,next;bool active;};
struct Circle{double y,x;int arc,left,right;}; struct Rat{std::int64_t n,d;}; struct RPoint{Rat x,y;};
std::int64_t gcd64(std::int64_t a,std::int64_t b){a=std::llabs(a);b=std::llabs(b);while(b){auto t=a%b;a=b;b=t;}return a?a:1;}
Rat rat(std::int64_t n,std::int64_t d){if(d<0){n=-n;d=-d;}auto g=gcd64(n,d);return {n/g,d/g};}
Rat add(Rat a,Rat b){return rat(a.n*b.d+b.n*a.d,a.d*b.d);} Rat sub(Rat a,Rat b){return rat(a.n*b.d-b.n*a.d,a.d*b.d);}
Rat mul(Rat a,Rat b){return rat(a.n*b.n,a.d*b.d);} Rat divr(Rat a,Rat b){return rat(a.n*b.d,a.d*b.n);}
int cmp(Rat a,Rat b){auto l=a.n*b.d,r=b.n*a.d;return l>r?1:l<r?-1:0;}
bool equal(RPoint a,RPoint b){return cmp(a.x,b.x)==0&&cmp(a.y,b.y)==0;}
bool lessp(RPoint a,RPoint b){int x=cmp(a.x,b.x);return x<0||(x==0&&cmp(a.y,b.y)<0);}
int orient(Point a,Point b,Point c){double x=(b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);return x>0?1:x<0?-1:0;}
double breakpoint(Point p,Point q,double y){if(std::fabs(p.y-q.y)<EPS)return (p.x+q.x)*.5;double dp=p.y-y,dq=q.y-y,a=q.y-p.y,b=-2*p.x*dq+2*q.x*dp,c=(p.x*p.x+p.y*p.y-y*y)*dq-(q.x*q.x+q.y*q.y-y*y)*dp;double d=b*b-4*a*c;if(d<0&&d>-EPS)d=0;double s=std::sqrt(d),r1=(-b-s)/(2*a),r2=(-b+s)/(2*a);return p.y<q.y?std::max(r1,r2):std::min(r1,r2);}
bool circle(Point a,Point b,Point c,double sweep,Circle& out,int arc,int left,int right){if(orient(a,b,c)>=0)return false;double aa=a.x*a.x+a.y*a.y,bb=b.x*b.x+b.y*b.y,cc=c.x*c.x+c.y*c.y,d=2*(a.x*(b.y-c.y)+b.x*(c.y-a.y)+c.x*(a.y-b.y));if(std::fabs(d)<EPS)return false;double x=(aa*(b.y-c.y)+bb*(c.y-a.y)+cc*(a.y-b.y))/d,y=(aa*(c.x-b.x)+bb*(a.x-c.x)+cc*(b.x-a.x))/d,dx=x-a.x,dy=y-a.y,bottom=y-std::sqrt(dx*dx+dy*dy);if(!(bottom<sweep-EPS))return false;out={bottom,x,arc,left,right};return true;}
Rat distance(RPoint p,std::int64_t a,std::int64_t b,std::int64_t c){return sub(add(mul(rat(a,1),p.x),mul(rat(b,1),p.y)),rat(c,1));}
RPoint intersect(RPoint p,RPoint q,Rat dp,Rat dq){Rat t=divr(dp,sub(dp,dq));return {add(p.x,mul(t,sub(q.x,p.x))),add(p.y,mul(t,sub(q.y,p.y)))};}
void push(std::array<RPoint,V>& p,int& n,RPoint q){if(n==0||!equal(p[n-1],q))p[n++]=q;}
int clip(std::array<RPoint,V>& p,int n,std::int64_t a,std::int64_t b,std::int64_t c){std::array<RPoint,V> q{};int m=0;for(int i=0;i<n;++i){auto x=p[i],y=p[(i+1)%n];auto dx=distance(x,a,b,c),dy=distance(y,a,b,c);bool ix=dx.n<=0,iy=dy.n<=0;if(ix&&iy)push(q,m,y);else if(ix&&!iy)push(q,m,intersect(x,y,dx,dy));else if(!ix&&iy){push(q,m,intersect(x,y,dx,dy));push(q,m,y);}}if(m>1&&equal(q[0],q[m-1]))--m;for(int i=0;i<m;++i)p[i]=q[i];return m;}
bool valid(const std::int64_t* v,int n){for(int i=0;i<n;++i)for(int j=i+1;j<n;++j)if((v[1+2*i]==v[1+2*j]&&v[2+2*i]==v[2+2*j])||v[2+2*i]==v[2+2*j])return false;for(int i=0;i<n;++i)for(int j=i+1;j<n;++j)for(int k=j+1;k<n;++k){auto ax=v[1+2*i],ay=v[2+2*i],bx=v[1+2*j],by=v[2+2*j],cx=v[1+2*k],cy=v[2+2*k];if((bx-ax)*(cy-ay)==(by-ay)*(cx-ax))return false;}for(int i=0;i<n;++i)for(int j=i+1;j<n;++j)for(int k=j+1;k<n;++k)for(int l=k+1;l<n;++l){auto ax=v[1+2*i]-v[1+2*l],ay=v[2+2*i]-v[2+2*l],bx=v[1+2*j]-v[1+2*l],by=v[2+2*j]-v[2+2*l],cx=v[1+2*k]-v[1+2*l],cy=v[2+2*k]-v[2+2*l];auto aa=ax*ax+ay*ay,bb=bx*bx+by*by,cc=cx*cx+cy*cy;auto d=ax*(by*cc-bb*cy)-ay*(bx*cc-bb*cx)+aa*(bx*cy-by*cx);if(d==0)return false;}return true;}
void put(std::uint8_t* out,std::size_t slot,std::int64_t v){auto b=static_cast<std::uint64_t>(v);for(int i=0;i<8;++i)out[slot*8+i]=static_cast<std::uint8_t>(b>>(8*i));}
}
extern "C" std::int64_t fortune_voronoi(const std::int64_t* in,std::size_t len,std::uint8_t* out,std::size_t cap){
 if(!in||len<3||in[0]<1||in[0]>N||len!=1+2*static_cast<std::size_t>(in[0]))return -1;int n=static_cast<int>(in[0]);for(int i=0;i<n;++i)if(in[1+2*i]<-8||in[1+2*i]>8||in[2+2*i]<-8||in[2+2*i]>8)return -1;if(!valid(in,n))return -1;
 std::array<Point,N>s{};std::array<int,N>order{};for(int i=0;i<n;++i){s[i]={static_cast<double>(in[1+2*i]),static_cast<double>(in[2+2*i])};order[i]=i;}for(int i=1;i<n;++i){int v=order[i],j=i;while(j>0&&s[order[j-1]].y<s[v].y){order[j]=order[j-1];--j;}order[j]=v;}
 std::array<Arc,A>arcs{};int ac=1,first=0;arcs[0]={order[0],-1,-1,true};int next=1;double sweep=s[order[0]].y;bool adj[N][N]{};
 while(next<n||first>=0){Circle best{};bool has=false;for(int b=first;b>=0;b=arcs[b].next){int l=arcs[b].prev,r=arcs[b].next;if(l<0||r<0)continue;int i=arcs[l].site,j=arcs[b].site,k=arcs[r].site;if(i==j||j==k||i==k)continue;Circle q;if(circle(s[i],s[j],s[k],sweep,q,b,l,r)&&(!has||q.y>best.y+EPS||(std::fabs(q.y-best.y)<=EPS&&b<best.arc))){best=q;has=true;}}
  bool dosite=next<n&&(!has||s[order[next]].y>best.y+EPS);if(!dosite&&!has)break;if(dosite){int site=order[next++];sweep=s[site].y;int arc=first;while(arcs[arc].next>=0){int r=arcs[arc].next;if(s[site].x<breakpoint(s[arcs[arc].site],s[arcs[r].site],sweep))break;arc=r;}int oldnext=arcs[arc].next,oldsite=arcs[arc].site;if(ac+2>A)return -1;int mid=ac++;arcs[mid]={site,arc,-1,true};int right=ac++;arcs[right]={oldsite,mid,oldnext,true};arcs[arc].next=mid;arcs[mid].next=right;if(oldnext>=0)arcs[oldnext].prev=right;adj[oldsite][site]=adj[site][oldsite]=true;}else{int arc=best.arc,l=best.left,r=best.right;if(!arcs[arc].active||arcs[arc].prev!=l||arcs[arc].next!=r)return -1;sweep=best.y;int x=arcs[l].site,y=arcs[r].site;adj[x][y]=adj[y][x]=true;arcs[l].next=r;arcs[r].prev=l;arcs[arc].active=false;}}
 std::array<std::int64_t,O>values{};std::size_t used=0;values[used++]=n;for(int i=0;i<n;++i){std::array<RPoint,V>p{};p[0]={{-16,1},{-16,1}};p[1]={{16,1},{-16,1}};p[2]={{16,1},{16,1}};p[3]={{-16,1},{16,1}};int count=4;for(int j=0;j<n;++j)if(adj[i][j]){auto x=in[1+2*j],y=in[2+2*j],sx=in[1+2*i],sy=in[2+2*i];count=clip(p,count,2*(x-sx),2*(y-sy),x*x+y*y-sx*sx-sy*sy);}if(count<3||used+2+4*count>O)return -1;int start=0;for(int j=1;j<count;++j)if(lessp(p[j],p[start]))start=j;values[used++]=i;values[used++]=count;for(int j=0;j<count;++j){auto q=p[(start+j)%count];values[used++]=q.x.n;values[used++]=q.x.d;values[used++]=q.y.n;values[used++]=q.y.d;}}
 auto bytes=used*8;if(!out||cap<bytes)return -2;for(std::size_t i=0;i<used;++i)put(out,i,values[i]);return static_cast<std::int64_t>(bytes);
}
