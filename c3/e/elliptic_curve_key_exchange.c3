module elliptic_curve_key_exchange;
struct Pt { bool inf; long x; long y; }
fn long md(long x,long p){long r=x%p;if(r<0)return r+p;return r;}
fn bool prime(long p){if(p<2)return false;for(long d=2;d*d<=p;d++){if(p%d==0)return false;}return true;}
fn long powm(long x,long n,long p){long r=1;x=md(x,p);while(n>0){if((n&1)!=0)r=r*x%p;x=x*x%p;n=n>>1;}return r;}
fn Pt inf(){Pt r;r.inf=true;r.x=0;r.y=0;return r;}
fn Pt add(long p,long a,Pt u,Pt v){if(u.inf)return v;if(v.inf)return u;if(u.x==v.x&&md(u.y+v.y,p)==0)return inf();long s;if(u.x==v.x&&u.y==v.y){s=md((3*u.x*u.x+a)*powm(2*u.y,p-2,p),p);}else{s=md((v.y-u.y)*powm(v.x-u.x,p-2,p),p);}long x=md(s*s-u.x-v.x,p);Pt r;r.inf=false;r.x=x;r.y=md(s*(u.x-x)-u.y,p);return r;}
fn Pt mul(long p,long a,Pt q,long k){Pt r=inf();while(k>0){if((k&1)!=0)r=add(p,a,r,q);k=k>>1;if(k>0)q=add(p,a,q,q);}return r;}
fn void put(char* o,usz k,long v){ulong b=(ulong)v;for(usz i=0;i<8;i++)o[k+i]=(char)((b>>(i*8))&255);}
fn long elliptic_curve_key_exchange(long* v,usz n,char* o,usz cap) @export("elliptic_curve_key_exchange") {
if(v==null||n!=7)return -1;
long p=v[0];long a=v[1];long b=v[2];long x=v[3];long y=v[4];long ka=v[5];long kb=v[6];
if(p<5||p>251||!prime(p)||a<0||a>=p||b<0||b>=p||x<0||x>=p||y<0||y>=p||ka<1||ka>1024||kb<1||kb>1024)return -1;
if(md(4*a*a*a+27*b*b,p)==0||md(y*y-x*x*x-a*x-b,p)!=0)return -1;
if(cap<48||o==null)return -2;
Pt g;g.inf=false;g.x=x;g.y=y;
Pt ap=mul(p,a,g,ka);Pt bp=mul(p,a,g,kb);Pt s=mul(p,a,ap,kb);Pt t=mul(p,a,bp,ka);
if(s.inf!=t.inf||(!s.inf&&(s.x!=t.x||s.y!=t.y)))return -1;
Pt[3] q;q[0]=ap;q[1]=bp;q[2]=s;
for(usz i=0;i<3;i++){put(o,i*16,q[i].inf?-1:q[i].x);put(o,i*16+8,q[i].inf?-1:q[i].y);}
return 48;
}
