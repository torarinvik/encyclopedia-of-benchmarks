#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 18, MAX_INPUT = 57, MAX_OUTPUT = 896, MAX_PATH = 37 };

typedef struct { int64_t x, y; } Point;
typedef struct { int64_t num, den; } Fraction;

static int64_t cross(int64_t ax, int64_t ay, int64_t bx, int64_t by)
{ return ax * by - ay * bx; }

static int64_t orient(Point a, Point b, Point c)
{ return cross(b.x-a.x, b.y-a.y, c.x-a.x, c.y-a.y); }

static int half(int64_t x, int64_t y)
{ return (y > 0 || (y == 0 && x >= 0)) ? 0 : 1; }

static bool angle_less(int64_t ax, int64_t ay, int ai, int64_t bx, int64_t by, int bi)
{
    int ah = half(ax, ay), bh = half(bx, by);
    if (ah != bh) return ah < bh;
    int64_t turn = cross(ax, ay, bx, by);
    return turn != 0 ? turn > 0 : ai < bi;
}

static int64_t gcd64(int64_t a, int64_t b)
{
    if (a < 0) a = -a;
    if (b < 0) b = -b;
    while (b != 0) { int64_t r = a % b; a = b; b = r; }
    return a;
}

static bool proper_crossing(Point p, Point q, Point a, Point b, Fraction *out)
{
    int64_t rx=q.x-p.x, ry=q.y-p.y, sx=b.x-a.x, sy=b.y-a.y;
    int64_t den=cross(rx,ry,sx,sy);
    if (den == 0) return false;
    int64_t ax=a.x-p.x, ay=a.y-p.y;
    int64_t tn=cross(ax,ay,sx,sy), un=cross(ax,ay,rx,ry);
    if (den < 0) { den=-den; tn=-tn; un=-un; }
    if (!(tn > 0 && tn < den && un > 0 && un < den)) return false;
    int64_t g=gcd64(tn,den);
    out->num=tn/g; out->den=den/g;
    return true;
}

static bool segments_cross(Point a, Point b, Point c, Point d)
{
    return orient(a,b,c)*orient(a,b,d)<0 && orient(c,d,a)*orient(c,d,b)<0;
}

static int next_ccw(int node, int incoming, int degree[MAX_N], int rotation[MAX_N][MAX_N])
{
    int *row=rotation[node];
    for (int i=0;i<degree[node];++i)
        if (row[i]==incoming) return row[(i+1)%degree[node]];
    return -1;
}

static int first_ccw(int node, int target, Point p[MAX_N], int degree[MAX_N], int adj[MAX_N][MAX_N])
{
    int best=-1; int64_t bestx=0,besty=0;
    int64_t rx=p[target].x-p[node].x, ry=p[target].y-p[node].y;
    for (int i=0;i<degree[node];++i) {
        int v=adj[node][i]; int64_t dx=p[v].x-p[node].x, dy=p[v].y-p[node].y;
        int64_t vx=rx*dx+ry*dy, vy=cross(rx,ry,dx,dy);
        if (best<0 || angle_less(vx,vy,v,bestx,besty,best)) { best=v; bestx=vx; besty=vy; }
    }
    return best;
}

static int edge_id(int u,int v,int m,int eu[MAX_M],int ev[MAX_M])
{
    if (u>v) { int t=u; u=v; v=t; }
    for (int i=0;i<m;++i) if (eu[i]==u && ev[i]==v) return i;
    return -1;
}

static void put64(uint8_t *out,size_t at,int64_t value)
{
    uint64_t bits=(uint64_t)value;
    for (size_t i=0;i<8;++i) out[at+i]=(uint8_t)(bits>>(8*i));
}

int64_t gpsr_perimeter_recovery_trace(const int64_t *input,size_t length,uint8_t *output,size_t capacity)
{
    if (input==NULL || length<4 || length>MAX_INPUT) return -1;
    int64_t n64=input[0],m64=input[1],s64=input[2],d64=input[3];
    if (n64<3 || n64>MAX_N || m64<n64-1 || m64>3*n64-6 || m64>MAX_M ||
        s64<0 || s64>=n64 || d64<0 || d64>=n64 || s64==d64) return -1;
    int n=(int)n64,m=(int)m64,s=(int)s64,d=(int)d64;
    if (length!=(size_t)(4+2*n+2*m)) return -1;
    Point p[MAX_N];
    for (int i=0;i<n;++i) {
        p[i].x=input[4+i]; p[i].y=input[4+n+i];
        if (p[i].x < -16 || p[i].x > 16 || p[i].y < -16 || p[i].y > 16) return -1;
        for (int j=0;j<i;++j) if (p[i].x==p[j].x && p[i].y==p[j].y) return -1;
    }
    for (int i=0;i<n;++i) for (int j=i+1;j<n;++j) for (int k=j+1;k<n;++k)
        if (orient(p[i],p[j],p[k])==0) return -1;
    int eu[MAX_M],ev[MAX_M],adj[MAX_N][MAX_N],degree[MAX_N]={0};
    size_t start=4u+2u*(size_t)n;
    for (int i=0;i<m;++i) {
        int64_t u=input[start+2u*(size_t)i],v=input[start+2u*(size_t)i+1];
        if (u<0 || v>=n || u>=v) return -1;
        eu[i]=(int)u; ev[i]=(int)v;
        if (i>0 && (eu[i-1]>eu[i] || (eu[i-1]==eu[i] && ev[i-1]>=ev[i]))) return -1;
        adj[u][degree[u]++]=(int)v; adj[v][degree[v]++]=(int)u;
    }
    bool seen[MAX_N]={false}; int queue[MAX_N],head=0,tail=0;
    seen[s]=true; queue[tail++]=s;
    while (head<tail) { int u=queue[head++]; for (int j=0;j<degree[u];++j) {
        int v=adj[u][j]; if (!seen[v]) { seen[v]=true; queue[tail++]=v; }
    }}
    for (int i=0;i<n;++i) if (!seen[i]) return -1;
    for (int i=0;i<m;++i) for (int j=i+1;j<m;++j) {
        if (eu[i]!=eu[j] && eu[i]!=ev[j] && ev[i]!=eu[j] && ev[i]!=ev[j] &&
            segments_cross(p[eu[i]],p[ev[i]],p[eu[j]],p[ev[j]])) return -1;
    }
    int64_t sx=p[s].x-p[d].x,sy=p[s].y-p[d].y,start_dist=sx*sx+sy*sy;
    for (int j=0;j<degree[s];++j) {
        int v=adj[s][j]; int64_t dx=p[v].x-p[d].x,dy=p[v].y-p[d].y;
        if (dx*dx+dy*dy<start_dist) return -1;
    }
    int rotation[MAX_N][MAX_N];
    for (int u=0;u<n;++u) {
        for (int i=0;i<degree[u];++i) rotation[u][i]=adj[u][i];
        for (int i=1;i<degree[u];++i) {
            int v=rotation[u][i],j=i;
            while (j>0) {
                int w=rotation[u][j-1];
                if (!angle_less(p[v].x-p[u].x,p[v].y-p[u].y,v,
                                p[w].x-p[u].x,p[w].y-p[u].y,w)) break;
                rotation[u][j]=w; --j;
            }
            rotation[u][j]=v;
        }
    }
    if (output==NULL || capacity<MAX_OUTPUT) return -2;
    int path[MAX_PATH],path_count=1,cross_count=0;
    int64_t events[MAX_M][4]; int current=s,previous=-1,e0u=-1,e0v=-1,status=0;
    Fraction lf={0,1}; path[0]=s;
    for (;;) {
        int64_t dx=p[current].x-p[d].x,dy=p[current].y-p[d].y;
        if (current==d) { status=2; break; }
        if (dx*dx+dy*dy<start_dist) { status=1; break; }
        if (path_count-1>=2*m) { status=0; break; }
        int candidate=previous<0 ? first_ccw(current,d,p,degree,adj) : next_ccw(current,previous,degree,rotation);
        if (candidate<0) { status=0; break; }
        bool changed=false;
        for (;;) {
            Fraction t;
            if (!proper_crossing(p[s],p[d],p[current],p[candidate],&t) ||
                t.num*lf.den<=lf.num*t.den) break;
            int id=edge_id(current,candidate,m,eu,ev);
            if (id<0 || cross_count>=MAX_M) { status=0; goto finished; }
            events[cross_count][0]=path_count-1; events[cross_count][1]=id;
            events[cross_count][2]=t.num; events[cross_count][3]=t.den; ++cross_count;
            lf=t; changed=true;
            int next=next_ccw(current,candidate,degree,rotation);
            if (next<0) { status=0; goto finished; }
            candidate=next;
        }
        if (changed || e0u<0) { e0u=current; e0v=candidate; }
        else if (e0u==current && e0v==candidate) { status=0; break; }
        previous=current; current=candidate;
        path[path_count++]=current;
    }
finished:
    ;
    int64_t words[112]; size_t count=0;
    words[count++]=status; words[count++]=path_count-1;
    for (int i=0;i<path_count;++i) words[count++]=path[i];
    words[count++]=cross_count;
    for (int i=0;i<cross_count;++i) for (int j=0;j<4;++j) words[count++]=events[i][j];
    for (size_t i=0;i<count;++i) put64(output,8*i,words[i]);
    return (int64_t)(8*count);
}
