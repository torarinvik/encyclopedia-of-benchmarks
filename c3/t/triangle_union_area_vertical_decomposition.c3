module triangle_union_area_vertical_decomposition;
const usz MT=3, MS=9, ME=45;
struct Rat { long n; long d; }
struct Seg { long x0; long y0; long x1; long y1; int id; }
struct Intv { Rat lo; Rat hi; Seg low; Seg high; int li; int hiid; }
fn long ab(long x){return x<0?-x:x;}
fn long gcd(long a,long b){a=ab(a);b=ab(b);while(b){long t=a%b;a=b;b=t;}return a?a:1;}
fn Rat rat(long n,long d){if(d<0){n=-n;d=-d;}long g=gcd(n,d);return Rat{n/g,d/g};}
fn Rat add(Rat a,Rat b){return rat(a.n*b.d+b.n*a.d,a.d*b.d);}
fn Rat sub(Rat a,Rat b){return rat(a.n*b.d-b.n*a.d,a.d*b.d);}
fn Rat mul(Rat a,Rat b){return rat(a.n*b.n,a.d*b.d);}
fn Rat divr(Rat a,Rat b){return rat(a.n*b.d,a.d*b.n);}
fn int cmp(Rat a,Rat b){long x=a.n*b.d,y=b.n*a.d;return x<y?-1:x>y?1:0;}
fn long cr(long ax,long ay,long bx,long by){return ax*by-ay*bx;}
fn long orient(long ax,long ay,long bx,long by,long cx,long cy){return cr(bx-ax,by-ay,cx-ax,cy-ay);}
fn Rat yat(Seg s,Rat x){return add(rat(s.y0,1),mul(rat(s.y1-s.y0,s.x1-s.x0),sub(x,rat(s.x0,1))));}
fn bool intersect(Seg a,Seg b,Rat* x){long rx=a.x1-a.x0,ry=a.y1-a.y0,sx=b.x1-b.x0,sy=b.y1-b.y0;long den=cr(rx,ry,sx,sy);if(!den)return false;long qx=b.x0-a.x0,qy=b.y0-a.y0;Rat t=rat(cr(qx,qy,sx,sy),den),u=rat(cr(qx,qy,rx,ry),den);if(cmp(t,rat(0,1))<0||cmp(t,rat(1,1))>0||cmp(u,rat(0,1))<0||cmp(u,rat(1,1))>0)return false;*x=add(rat(a.x0,1),mul(t,rat(rx,1)));return true;}
fn void event(Rat[45]* e,usz* n,Rat x){for(usz i=0;i<*n;i++)if(cmp((*e)[i],x)==0)return;(*e)[*n]=x;*n=*n+1;}
fn void integrate(Rat* area,Seg low,Seg high,Rat xl,Rat xr){Rat h0=sub(yat(high,xl),yat(low,xl)),h1=sub(yat(high,xr),yat(low,xr));*area=add(*area,mul(sub(xr,xl),divr(add(h0,h1),rat(2,1))));}
fn bool lessi(Intv a,Intv b){int c=cmp(a.lo,b.lo);if(c)return c<0;if(a.li!=b.li)return a.li<b.li;c=cmp(a.hi,b.hi);if(c)return c<0;return a.hiid<b.hiid;}

fn long triangle_union_area_vertical_decomposition(long* input,usz length,char* output,usz capacity) @export("triangle_union_area_vertical_decomposition") {
    if(input==null||length<1||length>19)return -1;long nv=input[0];if(nv<1||nv>3||length!=1+6*(usz)nv)return -1;int n=(int)nv;long[3][3][2] p=zeroed;
    for(int t=0;t<n;t++)for(int j=0;j<3;j++)for(int k=0;k<2;k++){long v=input[1+6*t+2*j+k];if(v < -1||v>1)return -1;p[t][j][k]=v;}
    for(int t=0;t<n;t++)if((p[t][0][0]==p[t][1][0]&&p[t][0][1]==p[t][1][1])||(p[t][0][0]==p[t][2][0]&&p[t][0][1]==p[t][2][1])||(p[t][1][0]==p[t][2][0]&&p[t][1][1]==p[t][2][1])||orient(p[t][0][0],p[t][0][1],p[t][1][0],p[t][1][1],p[t][2][0],p[t][2][1])==0)return -1;
    Seg[9] s=zeroed;Rat[45] ev=zeroed;usz ns=0,ne=0;for(int t=0;t<n;t++)for(int j=0;j<3;j++){int k=(j+1)%3;s[ns]=Seg{p[t][j][0],p[t][j][1],p[t][k][0],p[t][k][1],3*t+j};event(&ev,&ne,rat(s[ns].x0,1));ns++;}
    for(usz i=0;i<ns;i++)for(usz j=i+1;j<ns;j++){Rat x;if(intersect(s[i],s[j],&x))event(&ev,&ne,x);}for(usz i=1;i<ne;i++){Rat v=ev[i];usz j=i;while(j>0&&cmp(v,ev[j-1])<0){ev[j]=ev[j-1];j--;}ev[j]=v;}
    Rat area=rat(0,1);for(usz e=0;e+1<ne;e++){Rat xl=ev[e],xr=ev[e+1];if(cmp(xl,xr)>=0)continue;Rat xm=divr(add(xl,xr),rat(2,1));Intv[3] iv=zeroed;usz ni=0;
        for(int t=0;t<n;t++){Seg[3] crs=zeroed;Rat[3] ys=zeroed;usz count=0;for(int j=0;j<3;j++){Seg q=s[3*t+j];if(q.x0!=q.x1&&cmp(xm,rat(q.x0<q.x1?q.x0:q.x1,1))>0&&cmp(xm,rat(q.x0>q.x1?q.x0:q.x1,1))<0){crs[count]=q;ys[count]=yat(q,xm);count++;}}if(count==0)continue;if(count!=2)return -1;bool sw=cmp(ys[0],ys[1])>0||(cmp(ys[0],ys[1])==0&&crs[0].id>crs[1].id);iv[ni]=sw?Intv{ys[1],ys[0],crs[1],crs[0],crs[1].id,crs[0].id}:Intv{ys[0],ys[1],crs[0],crs[1],crs[0].id,crs[1].id};ni++;}
        for(usz i=1;i<ni;i++){Intv v=iv[i];usz j=i;while(j>0&&lessi(v,iv[j-1])){iv[j]=iv[j-1];j--;}iv[j]=v;}
        bool have=false;Seg low=zeroed,high=zeroed;Rat top=rat(0,1);int hid=0;for(usz i=0;i<ni;i++){if(!have){low=iv[i].low;high=iv[i].high;top=iv[i].hi;hid=iv[i].hiid;have=true;continue;}if(cmp(iv[i].lo,top)<=0){int c=cmp(iv[i].hi,top);if(c>0||(c==0&&iv[i].hiid<hid)){high=iv[i].high;top=iv[i].hi;hid=iv[i].hiid;}}else{integrate(&area,low,high,xl,xr);low=iv[i].low;high=iv[i].high;top=iv[i].hi;hid=iv[i].hiid;}}if(have)integrate(&area,low,high,xl,xr);
    }
    if(area.n<0||area.d<=0||area.n>11289600||area.d>2822400)return -1;if(output==null||capacity<16)return -2;for(usz j=0;j<8;j++){output[j]=(char)((ulong)area.n>>(8*j));output[8+j]=(char)((ulong)area.d>>(8*j));}return 16;
}
