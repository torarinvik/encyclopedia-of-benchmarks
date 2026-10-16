#include <cstddef>
#include <cstdint>
static void put(std::uint8_t* o,std::size_t k,std::int64_t v){auto b=static_cast<std::uint64_t>(v);for(int i=0;i<8;i++)o[k+i]=static_cast<std::uint8_t>(b>>(8*i));}
static bool prime_i(std::int64_t p){if(p<2)return false;for(std::int64_t d=2;d*d<=p;d++)if(p%d==0)return false;return true;}
static std::int64_t mod(std::int64_t x,std::int64_t p){x%=p;return x<0?x+p:x;}
static std::int64_t powm(std::int64_t x,std::int64_t n,std::int64_t p){std::int64_t r=1;x=mod(x,p);while(n){if(n&1)r=r*x%p;x=x*x%p;n>>=1;}return r;}
struct Pt{bool inf;std::int64_t x,y;};
static Pt add(std::int64_t p,std::int64_t a,Pt u,Pt v){if(u.inf)return v;if(v.inf)return u;if(u.x==v.x&&mod(u.y+v.y,p)==0)return {true,0,0};auto s=u.x==v.x&&u.y==v.y?mod((3*u.x*u.x+a)*powm(2*u.y,p-2,p),p):mod((v.y-u.y)*powm(v.x-u.x,p-2,p),p);auto x=mod(s*s-u.x-v.x,p),y=mod(s*(u.x-x)-u.y,p);return {false,x,y};}
static Pt mul(std::int64_t p,std::int64_t a,Pt q,std::int64_t k){Pt r{true,0,0};while(k){if(k&1)r=add(p,a,r,q);k>>=1;if(k)q=add(p,a,q,q);}return r;}
extern "C" std::int64_t elliptic_curve_key_exchange(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap){if(!v||n!=7)return -1;auto p=v[0],a=v[1],b=v[2],x=v[3],y=v[4],ka=v[5],kb=v[6];if(p<5||p>251||!prime_i(p)||a<0||a>=p||b<0||b>=p||x<0||x>=p||y<0||y>=p||ka<1||ka>1024||kb<1||kb>1024)return -1;if(mod(4*a*a*a+27*b*b,p)==0||mod(y*y-x*x*x-a*x-b,p)!=0)return -1;if(cap<48||!out)return -2;Pt g{false,x,y},ap=mul(p,a,g,ka),bp=mul(p,a,g,kb),s=mul(p,a,ap,kb),t=mul(p,a,bp,ka);if(s.inf!=t.inf||(!s.inf&&(s.x!=t.x||s.y!=t.y)))return -1;Pt q[3]={ap,bp,s};for(int i=0;i<3;i++){put(out,i*16,q[i].inf?-1:q[i].x);put(out,i*16+8,q[i].inf?-1:q[i].y);}return 48;}
