#include <stddef.h>
#include <stdint.h>

enum { MIN_N = 3, MAX_N = 4, MAX_LEN = 14 };
typedef struct { int64_t x, y, z; } Point;
typedef struct { int a, b, c; } Triangle;
typedef struct { int64_t num, den; } Slope;

static int64_t orient(const Point p[MAX_N], int a, int b, int c) {
    return (p[b].x-p[a].x)*(p[c].y-p[a].y)-(p[b].y-p[a].y)*(p[c].x-p[a].x);
}
static Slope slope(const Point p[MAX_N], Triangle t) {
    const Point a=p[t.a], b=p[t.b], c=p[t.c];
    const int64_t dx1=b.x-a.x, dy1=b.y-a.y, dz1=b.z-a.z;
    const int64_t dx2=c.x-a.x, dy2=c.y-a.y, dz2=c.z-a.z;
    const int64_t det=dx1*dy2-dx2*dy1;
    const int64_t gx=dz1*dy2-dz2*dy1, gy=dx1*dz2-dz1*dx2;
    return (Slope){gx*gx+gy*gy, det*det};
}
static int cmp(Slope a, Slope b) {
    const int64_t lhs=a.num*b.den, rhs=b.num*a.den;
    return (lhs>rhs)-(lhs<rhs);
}
static Slope tri_max(const Point p[MAX_N], Triangle t) { return slope(p,t); }
static Slope two_max(const Point p[MAX_N], Triangle a, Triangle b) {
    Slope x=slope(p,a), y=slope(p,b); return cmp(x,y)>=0?x:y;
}
static int anchor(const Point p[MAX_N], Triangle t, int q) {
    const Slope unused=slope(p,t); (void)unused;
    int v[3]={t.a,t.b,t.c}, other[2], used=0, pos=-1;
    for (int i=0;i<3;i++) { if(v[i]==q)pos=i; else other[used++]=v[i]; }
    const Point a=p[t.a], b=p[t.b], c=p[t.c];
    const int64_t dx1=b.x-a.x,dy1=b.y-a.y,dz1=b.z-a.z,dx2=c.x-a.x,dy2=c.y-a.y,dz2=c.z-a.z;
    const int64_t det=dx1*dy2-dx2*dy1, gx=dz1*dy2-dz2*dy1, gy=dx1*dz2-dz1*dx2;
    if (gx==0 && gy==0) return 0;
    const int64_t sign=det>0?1:-1, dx=-gx*sign, dy=-gy*sign;
    const int64_t ux=p[other[0]].x-p[q].x, uy=p[other[0]].y-p[q].y;
    const int64_t vx=p[other[1]].x-p[q].x, vy=p[other[1]].y-p[q].y;
    const int64_t turn=ux*vy-uy*vx, wedge=turn>0?1:-1;
    return pos>=0 && wedge*(ux*dy-uy*dx)>=0 && wedge*(dx*vy-dy*vx)>=0;
}
static int proper_cross(const Point p[MAX_N], int a, int b, int c, int d) {
    return orient(p,a,b,c)*orient(p,a,b,d)<0 && orient(p,c,d,a)*orient(p,c,d,b)<0;
}
static int rank_slope(const Point p[MAX_N], int n, Slope target) {
    Slope vals[4]; int count=0;
    for(int a=0;a<n;a++)for(int b=a+1;b<n;b++)for(int c=b+1;c<n;c++)vals[count++]=slope(p,(Triangle){a,b,c});
    int distinct=0;
    for(int i=0;i<count;i++)if(cmp(vals[i],target)<0){int seen=0;for(int j=0;j<i;j++)if(cmp(vals[j],vals[i])==0)seen=1;if(!seen)distinct++;}
    return distinct+1;
}
static int64_t volume6(const Point p[MAX_N]) {
    const int64_t ax=p[1].x-p[0].x,ay=p[1].y-p[0].y,az=p[1].z-p[0].z;
    const int64_t bx=p[2].x-p[0].x,by=p[2].y-p[0].y,bz=p[2].z-p[0].z;
    const int64_t cx=p[3].x-p[0].x,cy=p[3].y-p[0].y,cz=p[3].z-p[0].z;
    return ax*(by*cz-bz*cy)-ay*(bx*cz-bz*cx)+az*(bx*cy-by*cx);
}
int64_t convex_polygon_minimax_slope_edge_insertion(const int64_t *input, size_t length) {
    if(input==NULL||length<1||length>MAX_LEN)return -1;
    const int64_t raw_n=input[0]; if(raw_n<MIN_N||raw_n>MAX_N)return -1;
    const int n=(int)raw_n; if(length!=(size_t)(1+3*n))return -1;
    Point p[MAX_N];
    for(int i=0;i<n;i++){p[i]=(Point){input[1+3*i],input[2+3*i],input[3+3*i]};if(p[i].x < -8||p[i].x>8||p[i].y < -8||p[i].y>8||p[i].z < -8||p[i].z>8)return -1;}
    int64_t area=0;for(int i=0;i<n;i++){int j=(i+1)%n;area+=p[i].x*p[j].y-p[i].y*p[j].x;}if(area==0)return -1;
    const int sign=area>0?1:-1;
    for(int a=0;a<n;a++)for(int b=a+1;b<n;b++)for(int c=b+1;c<n;c++)if(orient(p,a,b,c)==0)return -1;
    for(int e=0;e<n;e++){int j=(e+1)%n;for(int k=0;k<n;k++)if(k!=e&&k!=j&&sign*orient(p,e,j,k)<=0)return -1;}
    if(n==4&&volume6(p)==0)return -1;
    Triangle fan[2]={{0,1,2},{0,2,3}};
    Slope worst=n==3?tri_max(p,fan[0]):two_max(p,fan[0],fan[1]);
    if(n==4){int accepted=0;for(int ti=0;ti<2&&!accepted;ti++){Triangle t=fan[ti];if(cmp(slope(p,t),worst)!=0)continue;int v[3]={t.a,t.b,t.c};for(int k=0;k<3&&!accepted;k++){int q=v[k];if(!anchor(p,t,q))continue;int o[2],u=0,s=-1;for(int j=0;j<3;j++)if(j!=k)o[u++]=v[j];for(int j=0;j<4;j++)if(j!=v[0]&&j!=v[1]&&j!=v[2])s=j;if(!proper_cross(p,q,s,o[0],o[1]))continue;Triangle x={q,s,o[0]},y={q,s,o[1]};Slope candidate=two_max(p,x,y);if(cmp(candidate,worst)<0){worst=candidate;accepted=1;}}}}
    return rank_slope(p,n,worst);
}
