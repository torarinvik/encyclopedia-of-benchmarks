#include <stddef.h>
#include <stdint.h>

enum { MAX_T=3, MAX_S=9, MAX_E=45, MAX_INPUT_LENGTH=19 };
typedef struct { int64_t n,d; } Rat;
typedef struct { int64_t x0,y0,x1,y1; int id; } Seg;
typedef struct { Rat lo,hi; Seg low,high; int low_id,high_id; } Interval;
static int64_t absi(int64_t x){return x<0?-x:x;}
static int64_t gcd64(int64_t a,int64_t b){a=absi(a);b=absi(b);while(b){int64_t t=a%b;a=b;b=t;}return a?a:1;}
static Rat rat(int64_t n,int64_t d){if(d<0){n=-n;d=-d;}int64_t g=gcd64(n,d);return (Rat){n/g,d/g};}
static Rat add(Rat a,Rat b){return rat(a.n*b.d+b.n*a.d,a.d*b.d);}
static Rat subr(Rat a,Rat b){return rat(a.n*b.d-b.n*a.d,a.d*b.d);}
static Rat mul(Rat a,Rat b){return rat(a.n*b.n,a.d*b.d);}
static Rat divr(Rat a,Rat b){return rat(a.n*b.d,a.d*b.n);}
static int cmp(Rat a,Rat b){int64_t x=a.n*b.d,y=b.n*a.d;return x<y?-1:x>y?1:0;}
static int64_t crossi(int64_t ax,int64_t ay,int64_t bx,int64_t by){return ax*by-ay*bx;}
static int orient(int64_t ax,int64_t ay,int64_t bx,int64_t by,int64_t cx,int64_t cy){return crossi(bx-ax,by-ay,cx-ax,cy-ay);}
static Rat y_at(Seg s,Rat x){return add(rat(s.y0,1),mul(rat(s.y1-s.y0,s.x1-s.x0),subr(x,rat(s.x0,1))));}
static int in_segment(Rat x,int64_t lo,int64_t hi){return cmp(x,rat(lo<hi?lo:hi,1))>=0&&cmp(x,rat(lo>hi?lo:hi,1))<=0;}
static int intersect_x(Seg a,Seg b,Rat *x){
    int64_t rx=a.x1-a.x0,ry=a.y1-a.y0,sx=b.x1-b.x0,sy=b.y1-b.y0;
    int64_t den=crossi(rx,ry,sx,sy); if(!den)return 0;
    int64_t qx=b.x0-a.x0,qy=b.y0-a.y0;
    Rat t=rat(crossi(qx,qy,sx,sy),den),u=rat(crossi(qx,qy,rx,ry),den);
    if(cmp(t,rat(0,1))<0||cmp(t,rat(1,1))>0||cmp(u,rat(0,1))<0||cmp(u,rat(1,1))>0)return 0;
    *x=add(rat(a.x0,1),mul(t,rat(rx,1)));return 1;
}
static void add_event(Rat *e,int *n,Rat x){for(int i=0;i<*n;i++)if(cmp(e[i],x)==0)return;e[(*n)++]=x;}
static void integrate(Rat *area,Seg low,Seg high,Rat xl,Rat xr){
    Rat h0=subr(y_at(high,xl),y_at(low,xl)),h1=subr(y_at(high,xr),y_at(low,xr));
    *area=add(*area,mul(subr(xr,xl),divr(add(h0,h1),rat(2,1))));
}
static int less_interval(Interval a,Interval b){int c=cmp(a.lo,b.lo);if(c)return c<0;if(a.low_id!=b.low_id)return a.low_id<b.low_id;c=cmp(a.hi,b.hi);if(c)return c<0;return a.high_id<b.high_id;}

int64_t triangle_union_area_vertical_decomposition(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(!input||length<1||length>MAX_INPUT_LENGTH)return -1;
    int64_t nv=input[0];if(nv<1||nv>MAX_T||length!=1+6*(size_t)nv)return -1;int n=(int)nv;
    int64_t p[MAX_T][3][2];for(int t=0;t<n;t++)for(int j=0;j<3;j++)for(int k=0;k<2;k++){int64_t v=input[1+6*t+2*j+k];if(v < -1||v>1)return -1;p[t][j][k]=v;}
    for(int t=0;t<n;t++)if(p[t][0][0]==p[t][1][0]&&p[t][0][1]==p[t][1][1]||p[t][0][0]==p[t][2][0]&&p[t][0][1]==p[t][2][1]||p[t][1][0]==p[t][2][0]&&p[t][1][1]==p[t][2][1]||orient(p[t][0][0],p[t][0][1],p[t][1][0],p[t][1][1],p[t][2][0],p[t][2][1])==0)return -1;
    Seg s[MAX_S];int ns=0;Rat ev[MAX_E];int ne=0;
    for(int t=0;t<n;t++)for(int j=0;j<3;j++){int k=(j+1)%3;s[ns]=(Seg){p[t][j][0],p[t][j][1],p[t][k][0],p[t][k][1],3*t+j};add_event(ev,&ne,rat(s[ns].x0,1));ns++;}
    for(int i=0;i<ns;i++)for(int j=i+1;j<ns;j++){Rat x;if(intersect_x(s[i],s[j],&x))add_event(ev,&ne,x);}
    for(int i=1;i<ne;i++){Rat v=ev[i];int j=i;while(j>0&&cmp(v,ev[j-1])<0){ev[j]=ev[j-1];j--;}ev[j]=v;}
    Rat area=rat(0,1);
    for(int e=0;e+1<ne;e++){
        Rat xl=ev[e],xr=ev[e+1];if(cmp(xl,xr)>=0)continue;Rat xm=divr(add(xl,xr),rat(2,1));Interval iv[MAX_T];int ni=0;
        for(int t=0;t<n;t++){Seg cross[3];Rat ys[3];int count=0;for(int j=0;j<3;j++){Seg q=s[3*t+j];if(q.x0!=q.x1&&cmp(xm,rat(q.x0<q.x1?q.x0:q.x1,1))>0&&cmp(xm,rat(q.x0>q.x1?q.x0:q.x1,1))<0){cross[count]=q;ys[count]=y_at(q,xm);count++;}}if(count==0)continue;if(count!=2)return -1;if(cmp(ys[0],ys[1])<0||(cmp(ys[0],ys[1])==0&&cross[0].id<cross[1].id))iv[ni++]=(Interval){ys[0],ys[1],cross[0],cross[1],cross[0].id,cross[1].id};else iv[ni++]=(Interval){ys[1],ys[0],cross[1],cross[0],cross[1].id,cross[0].id};}
        for(int i=1;i<ni;i++){Interval v=iv[i];int j=i;while(j>0&&less_interval(v,iv[j-1])){iv[j]=iv[j-1];j--;}iv[j]=v;}
        int has=0;Seg low={0},high={0};Rat top=rat(0,1);int highid=0;
        for(int i=0;i<ni;i++){if(!has){low=iv[i].low;high=iv[i].high;top=iv[i].hi;highid=iv[i].high_id;has=1;continue;}if(cmp(iv[i].lo,top)<=0){int c=cmp(iv[i].hi,top);if(c>0||(c==0&&iv[i].high_id<highid)){high=iv[i].high;top=iv[i].hi;highid=iv[i].high_id;}}else{integrate(&area,low,high,xl,xr);low=iv[i].low;high=iv[i].high;top=iv[i].hi;highid=iv[i].high_id;}}
        if(has)integrate(&area,low,high,xl,xr);
    }
    if(area.n<0||area.d<=0||area.n>11289600||area.d>2822400)return -1;
    if(!output||capacity<16)return -2;
    for(int j=0;j<8;j++){output[j]=(uint8_t)((uint64_t)area.n>>(8*j));output[8+j]=(uint8_t)((uint64_t)area.d>>(8*j));}return 16;
}
