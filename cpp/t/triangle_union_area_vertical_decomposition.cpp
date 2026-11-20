#include <cstddef>
#include <cstdint>

namespace {
constexpr int MT=3, MS=9, ME=45;
struct R{std::int64_t n,d;};
struct S{std::int64_t x0,y0,x1,y1;int id;};
struct I{R lo,hi;S low,high;int li,hiid;};
std::int64_t ab(std::int64_t x){return x<0?-x:x;}
std::int64_t gcd(std::int64_t a,std::int64_t b){a=ab(a);b=ab(b);while(b){auto t=a%b;a=b;b=t;}return a?a:1;}
R r(std::int64_t n,std::int64_t d){if(d<0){n=-n;d=-d;}auto g=gcd(n,d);return {n/g,d/g};}
R add(R a,R b){return r(a.n*b.d+b.n*a.d,a.d*b.d);} R sub(R a,R b){return r(a.n*b.d-b.n*a.d,a.d*b.d);} R mul(R a,R b){return r(a.n*b.n,a.d*b.d);} R divv(R a,R b){return r(a.n*b.d,a.d*b.n);}
int cmp(R a,R b){auto x=a.n*b.d,y=b.n*a.d;return x<y?-1:x>y?1:0;}
std::int64_t cross(std::int64_t ax,std::int64_t ay,std::int64_t bx,std::int64_t by){return ax*by-ay*bx;}
std::int64_t orient(std::int64_t ax,std::int64_t ay,std::int64_t bx,std::int64_t by,std::int64_t cx,std::int64_t cy){return cross(bx-ax,by-ay,cx-ax,cy-ay);}
R y_at(S s,R x){return add(r(s.y0,1),mul(r(s.y1-s.y0,s.x1-s.x0),sub(x,r(s.x0,1))));}
bool inter(S a,S b,R&x){auto rx=a.x1-a.x0,ry=a.y1-a.y0,sx=b.x1-b.x0,sy=b.y1-b.y0;auto den=cross(rx,ry,sx,sy);if(!den)return false;auto qx=b.x0-a.x0,qy=b.y0-a.y0;R t=r(cross(qx,qy,sx,sy),den),u=r(cross(qx,qy,rx,ry),den);if(cmp(t,r(0,1))<0||cmp(t,r(1,1))>0||cmp(u,r(0,1))<0||cmp(u,r(1,1))>0)return false;x=add(r(a.x0,1),mul(t,r(rx,1)));return true;}
void event(R* e,int&n,R x){for(int i=0;i<n;i++)if(cmp(e[i],x)==0)return;e[n++]=x;}
void integrate(R&area,S lo,S hi,R xl,R xr){R h0=sub(y_at(hi,xl),y_at(lo,xl)),h1=sub(y_at(hi,xr),y_at(lo,xr));area=add(area,mul(sub(xr,xl),divv(add(h0,h1),r(2,1))));}
bool lessI(I a,I b){int c=cmp(a.lo,b.lo);if(c)return c<0;if(a.li!=b.li)return a.li<b.li;c=cmp(a.hi,b.hi);if(c)return c<0;return a.hiid<b.hiid;}
}

extern "C" std::int64_t triangle_union_area_vertical_decomposition(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap){
 if(!in||len<1||len>19)return -1;auto nv=in[0];if(nv<1||nv>MT||len!=1+6*std::size_t(nv))return -1;int n=int(nv);std::int64_t p[MT][3][2];
 for(int t=0;t<n;t++)for(int j=0;j<3;j++)for(int k=0;k<2;k++){auto v=in[1+6*t+2*j+k];if(v< -1||v>1)return -1;p[t][j][k]=v;}
 for(int t=0;t<n;t++)if((p[t][0][0]==p[t][1][0]&&p[t][0][1]==p[t][1][1])||(p[t][0][0]==p[t][2][0]&&p[t][0][1]==p[t][2][1])||(p[t][1][0]==p[t][2][0]&&p[t][1][1]==p[t][2][1])||orient(p[t][0][0],p[t][0][1],p[t][1][0],p[t][1][1],p[t][2][0],p[t][2][1])==0)return -1;
 S s[MS];int ns=0;R ev[ME];int ne=0;for(int t=0;t<n;t++)for(int j=0;j<3;j++){int k=(j+1)%3;s[ns]={p[t][j][0],p[t][j][1],p[t][k][0],p[t][k][1],3*t+j};event(ev,ne,r(s[ns].x0,1));ns++;}
 for(int i=0;i<ns;i++)for(int j=i+1;j<ns;j++){R x;if(inter(s[i],s[j],x))event(ev,ne,x);}for(int i=1;i<ne;i++){R v=ev[i];int j=i;while(j&&cmp(v,ev[j-1])<0){ev[j]=ev[j-1];--j;}ev[j]=v;}
 R area=r(0,1);for(int e=0;e+1<ne;e++){R xl=ev[e],xr=ev[e+1];if(cmp(xl,xr)>=0)continue;R xm=divv(add(xl,xr),r(2,1));I iv[MT];int ni=0;
  for(int t=0;t<n;t++){S cr[3];R ys[3];int count=0;for(int j=0;j<3;j++){S q=s[3*t+j];if(q.x0!=q.x1&&cmp(xm,r(q.x0<q.x1?q.x0:q.x1,1))>0&&cmp(xm,r(q.x0>q.x1?q.x0:q.x1,1))<0){cr[count]=q;ys[count]=y_at(q,xm);count++;}}if(!count)continue;if(count!=2)return -1;bool sw=cmp(ys[0],ys[1])>0||(cmp(ys[0],ys[1])==0&&cr[0].id>cr[1].id);iv[ni++]=sw?I{ys[1],ys[0],cr[1],cr[0],cr[1].id,cr[0].id}:I{ys[0],ys[1],cr[0],cr[1],cr[0].id,cr[1].id};}
  for(int i=1;i<ni;i++){I v=iv[i];int j=i;while(j&&lessI(v,iv[j-1])){iv[j]=iv[j-1];--j;}iv[j]=v;}
  bool have=false;S low{},high{};R top=r(0,1);int hid=0;for(int i=0;i<ni;i++){if(!have){low=iv[i].low;high=iv[i].high;top=iv[i].hi;hid=iv[i].hiid;have=true;continue;}if(cmp(iv[i].lo,top)<=0){int c=cmp(iv[i].hi,top);if(c>0||(c==0&&iv[i].hiid<hid)){high=iv[i].high;top=iv[i].hi;hid=iv[i].hiid;}}else{integrate(area,low,high,xl,xr);low=iv[i].low;high=iv[i].high;top=iv[i].hi;hid=iv[i].hiid;}}if(have)integrate(area,low,high,xl,xr);
 }
 if(area.n<0||area.d<=0||area.n>11289600||area.d>2822400)return -1;if(!out||cap<16)return -2;for(int j=0;j<8;j++){out[j]=std::uint8_t(std::uint64_t(area.n)>>(8*j));out[8+j]=std::uint8_t(std::uint64_t(area.d)>>(8*j));}return 16;
}
