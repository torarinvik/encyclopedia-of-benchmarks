#include <cstddef>
#include <cstdint>

struct Point { bool infinity; std::int64_t x, y; };
static std::int64_t modp(std::int64_t v, std::int64_t m) { auto r=v%m; return r<0?r+m:r; }
static std::int64_t inverse(std::int64_t v, std::int64_t m) {
    std::int64_t old_r=m, r=modp(v,m), old_t=0, t=1;
    while(r){auto q=old_r/r;auto nr=old_r-q*r;auto nt=old_t-q*t;old_r=r;r=nr;old_t=t;t=nt;}
    return old_r==1?modp(old_t,m):0;
}
static Point inf() { return {true,0,0}; }
static Point add(Point u, Point v) {
    if(u.infinity)return v;if(v.infinity)return u;
    if(u.x==v.x&&modp(u.y+v.y,17)==0)return inf();
    auto num=u.x==v.x&&u.y==v.y?modp(3*u.x*u.x+2,17):modp(v.y-u.y,17);
    auto den=u.x==v.x&&u.y==v.y?modp(2*u.y,17):modp(v.x-u.x,17);
    auto slope=modp(num*inverse(den,17),17);
    auto x=modp(slope*slope-u.x-v.x,17);
    return {false,x,modp(slope*(u.x-x)-u.y,17)};
}
static Point multiply(Point q,std::int64_t k) {
    Point r=inf();while(k>0){if(k&1)r=add(r,q);k>>=1;if(k>0)q=add(q,q);}return r;
}
static bool on_curve(Point q) { return modp(q.y*q.y-q.x*q.x*q.x-2*q.x-2,17)==0; }
extern "C" std::int64_t ecdsa_signature_verification(const std::int64_t* v,std::size_t n,std::uint8_t* out,std::size_t cap) {
    if(!v||n!=11)return -1;
    auto p=v[0],a=v[1],b=v[2],gx=v[3],gy=v[4],order=v[5],qx=v[6],qy=v[7],z=v[8],r=v[9],s=v[10];
    if(p!=17||a!=2||b!=2||gx!=5||gy!=1||order!=19)return -1;
    if(modp(4*a*a*a+27*b*b,p)==0||qx<0||qx>=p||qy<0||qy>=p||z<0||z>31||r<1||r>=order||s<1||s>=order)return -1;
    Point g{false,gx,gy},q{false,qx,qy};
    if(!on_curve(g)||!on_curve(q)||!multiply(g,order).infinity||!multiply(q,order).infinity)return -1;
    if(!out||cap<1)return -2;
    auto w=inverse(s,order);if(w==0)return -1;
    auto u1=z*w%order,u2=r*w%order;
    auto point=add(multiply(g,u1),multiply(q,u2));
    out[0]=static_cast<std::uint8_t>(!point.infinity&&point.x%order==r);
    return 1;
}
