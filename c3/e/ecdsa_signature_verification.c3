module ecdsa_signature_verification;
struct Point { bool infinity; long x; long y; }
fn long md(long v,long m){long r=v%m;if(r<0)return r+m;return r;}
fn long inverse(long v,long m){long old_r=m;long r=md(v,m);long old_t=0;long t=1;while(r!=0){long q=old_r/r;long nr=old_r-q*r;long nt=old_t-q*t;old_r=r;r=nr;old_t=t;t=nt;}if(old_r!=1)return 0;return md(old_t,m);}
fn Point inf(){Point p;p.infinity=true;p.x=0;p.y=0;return p;}
fn Point add(Point u,Point v){if(u.infinity)return v;if(v.infinity)return u;if(u.x==v.x&&md(u.y+v.y,17)==0)return inf();long num;long den;if(u.x==v.x&&u.y==v.y){num=md(3*u.x*u.x+2,17);den=md(2*u.y,17);}else{num=md(v.y-u.y,17);den=md(v.x-u.x,17);}long slope=md(num*inverse(den,17),17);long x=md(slope*slope-u.x-v.x,17);Point p;p.infinity=false;p.x=x;p.y=md(slope*(u.x-x)-u.y,17);return p;}
fn Point mul(Point q,long k){Point r=inf();while(k>0){if((k&1)!=0)r=add(r,q);k=k>>1;if(k>0)q=add(q,q);}return r;}
fn bool on_curve(Point q){return md(q.y*q.y-q.x*q.x*q.x-2*q.x-2,17)==0;}
fn long ecdsa_signature_verification(long* v,usz n,char* o,usz cap) @export("ecdsa_signature_verification") {
if(v==null||n!=11)return -1;
long p=v[0];long a=v[1];long b=v[2];long gx=v[3];long gy=v[4];long order=v[5];long qx=v[6];long qy=v[7];long z=v[8];long r=v[9];long s=v[10];
if(p!=17||a!=2||b!=2||gx!=5||gy!=1||order!=19)return -1;
if(md(4*a*a*a+27*b*b,p)==0||qx<0||qx>=p||qy<0||qy>=p||z<0||z>31||r<1||r>=order||s<1||s>=order)return -1;
Point g;g.infinity=false;g.x=gx;g.y=gy;Point q;q.infinity=false;q.x=qx;q.y=qy;
if(!on_curve(g)||!on_curve(q)||!mul(g,order).infinity||!mul(q,order).infinity)return -1;
if(o==null||cap<1)return -2;
long w=inverse(s,order);if(w==0)return -1;long u1=z*w%order;long u2=r*w%order;Point check=add(mul(g,u1),mul(q,u2));o[0]=(char)(!check.infinity&&check.x%order==r);return 1;
}
