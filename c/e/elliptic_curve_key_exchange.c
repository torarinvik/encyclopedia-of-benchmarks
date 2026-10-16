#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

static void put(uint8_t *o, size_t k, int64_t v) {
    uint64_t b = (uint64_t)v;
    for (int i=0;i<8;i++) o[k+(size_t)i]=(uint8_t)(b>>(8*i));
}
static int prime_i(int64_t p) { if(p<2)return 0; for(int64_t d=2;d*d<=p;d++)if(p%d==0)return 0; return 1; }
static int64_t mod(int64_t x,int64_t p){x%=p;return x<0?x+p:x;}
static int64_t powm(int64_t x,int64_t n,int64_t p){int64_t r=1;x=mod(x,p);while(n){if(n&1)r=r*x%p;x=x*x%p;n>>=1;}return r;}
typedef struct { int inf; int64_t x,y; } Pt;
static Pt add(int64_t p,int64_t a,Pt u,Pt v){
    if(u.inf)return v;if(v.inf)return u;
    if(u.x==v.x && mod(u.y+v.y,p)==0)return (Pt){1,0,0};
    int64_t s;
    if(u.x==v.x && u.y==v.y)s=mod((3*u.x*u.x+a)*powm(2*u.y,p-2,p),p);
    else s=mod((v.y-u.y)*powm(v.x-u.x,p-2,p),p);
    int64_t x=mod(s*s-u.x-v.x,p), y=mod(s*(u.x-x)-u.y,p);
    return (Pt){0,x,y};
}
static Pt mul(int64_t p,int64_t a,Pt q,int64_t k){Pt r={1,0,0};while(k){if(k&1)r=add(p,a,r,q);k>>=1;if(k)q=add(p,a,q,q);}return r;}
int64_t elliptic_curve_key_exchange(const int64_t *v,size_t n,uint8_t *out,size_t cap){
    if(!v||n!=7)return -1;
    int64_t p=v[0],a=v[1],b=v[2],x=v[3],y=v[4],ka=v[5],kb=v[6];
    if(p<5||p>251||!prime_i(p)||a<0||a>=p||b<0||b>=p||x<0||x>=p||y<0||y>=p||ka<1||ka>1024||kb<1||kb>1024)return -1;
    if(mod(4*a*a*a+27*b*b,p)==0||mod(y*y-x*x*x-a*x-b,p)!=0)return -1;
    if(cap<48||!out)return -2;
    Pt g={0,x,y},ap=mul(p,a,g,ka),bp=mul(p,a,g,kb),s=mul(p,a,ap,kb),t=mul(p,a,bp,ka);
    if(s.inf!=t.inf||(!s.inf&&(s.x!=t.x||s.y!=t.y)))return -1;
    Pt q[3]={ap,bp,s};for(int i=0;i<3;i++){put(out,(size_t)i*16,q[i].inf?-1:q[i].x);put(out,(size_t)i*16+8,q[i].inf?-1:q[i].y);}return 48;
}
