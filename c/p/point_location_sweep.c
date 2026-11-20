#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_M 24
#define MAX_Q 16
#define MAX_EVENTS 64
#define MAX_LENGTH 141

typedef struct { int64_t x, y; } Point;
typedef struct { int64_t x, kind, id; } Event;

static int64_t orient(Point a, Point b, Point c) {
    return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);
}
static int between(int64_t x, int64_t a, int64_t b) {
    return x >= (a < b ? a : b) && x <= (a > b ? a : b);
}
static int on_segment(Point a, Point b, Point p) {
    return orient(a,b,p)==0 && between(p.x,a.x,b.x) && between(p.y,a.y,b.y);
}
static int intersects(Point a, Point b, Point c, Point d) {
    int64_t o1=orient(a,b,c), o2=orient(a,b,d), o3=orient(c,d,a), o4=orient(c,d,b);
    if ((o1==0 && on_segment(a,b,c)) || (o2==0 && on_segment(a,b,d)) ||
        (o3==0 && on_segment(c,d,a)) || (o4==0 && on_segment(c,d,b))) return 1;
    return ((o1<0 && o2>0)||(o1>0 && o2<0)) && ((o3<0 && o4>0)||(o3>0 && o4<0));
}
static void endpoints(Point *p, int64_t *u, int64_t *v, int e, Point *left, Point *right) {
    Point a=p[u[e]], b=p[v[e]];
    if (a.x < b.x) { *left=a; *right=b; } else { *left=b; *right=a; }
}
static void height(Point *p, int64_t *u, int64_t *v, int e, int64_t x, int64_t *num, int64_t *den) {
    Point a,b; endpoints(p,u,v,e,&a,&b); *den=b.x-a.x; *num=a.y*(*den)+(b.y-a.y)*(x-a.x);
}
static int edge_less(Point *p,int64_t *u,int64_t *v,int a,int b,int64_t x) {
    int64_t na,da,nb,db; Point la,ra,lb,rb;
    height(p,u,v,a,x,&na,&da); height(p,u,v,b,x,&nb,&db);
    if (na*db != nb*da) return na*db < nb*da;
    endpoints(p,u,v,a,&la,&ra); endpoints(p,u,v,b,&lb,&rb);
    int64_t sa=(ra.y-la.y)*(rb.x-lb.x), sb=(rb.y-lb.y)*(ra.x-la.x);
    if (sa != sb) return sa < sb;
    return a < b;
}
static int event_less(Event a, Event b) {
    if (a.x != b.x) return a.x < b.x;
    if (a.kind != b.kind) return a.kind < b.kind;
    return a.id < b.id;
}
int64_t point_location_sweep(const int64_t *a, size_t length) {
    if (a==NULL || length<4 || length>MAX_LENGTH) return -1;
    int64_t n=a[0], m=a[1], q=a[2], f=a[3];
    if (n<2||n>MAX_N||m<1||m>MAX_M||q<0||q>MAX_Q||f<1||f>16 ||
        length!=(size_t)(4+2*n+3*m+2*q)) return -1;
    Point p[MAX_N]; int64_t u[MAX_M],v[MAX_M],face[MAX_M],qx[MAX_Q],qy[MAX_Q];
    size_t at=4;
    for(int i=0;i<n;i++) {
        p[i].x=a[at++]; p[i].y=a[at++];
        if(p[i].x < -300||p[i].x>300||p[i].y < -300||p[i].y>300) return -1;
        for(int j=0;j<i;j++) if(p[i].x==p[j].x) return -1;
    }
    for(int i=0;i<m;i++) {
        u[i]=a[at++]; v[i]=a[at++]; face[i]=a[at++];
        if(u[i]<0||u[i]>=n||v[i]<0||v[i]>=n||u[i]==v[i]||face[i]<-1||face[i]>=f) return -1;
        for(int j=0;j<i;j++) if((u[i]==u[j]&&v[i]==v[j])||(u[i]==v[j]&&v[i]==u[j])) return -1;
    }
    for(int i=0;i<m;i++) for(int j=0;j<i;j++) {
        int64_t shared=-1;
        if(u[i]==u[j]||u[i]==v[j]) shared=u[i];
        else if(v[i]==u[j]||v[i]==v[j]) shared=v[i];
        if(shared>=0) {
            int64_t oi=(u[i]==shared)?v[i]:u[i], oj=(u[j]==shared)?v[j]:u[j];
            if(orient(p[shared],p[oi],p[oj])==0) return -1;
        } else if(intersects(p[u[i]],p[v[i]],p[u[j]],p[v[j]])) return -1;
    }
    for(int i=0;i<q;i++) {
        qx[i]=a[at++]; qy[i]=a[at++];
        if(qx[i]<-300||qx[i]>300||qy[i]<-300||qy[i]>300) return -1;
        for(int j=0;j<n;j++) if(qx[i]==p[j].x) return -1;
    }
    Event events[MAX_EVENTS]; int ec=0;
    for(int i=0;i<m;i++) { Point l,r; endpoints(p,u,v,i,&l,&r); events[ec++]=(Event){l.x,1,i}; events[ec++]=(Event){r.x,0,i}; }
    for(int i=0;i<q;i++) events[ec++]=(Event){qx[i],2,i};
    for(int i=1;i<ec;i++) { Event key=events[i]; int j=i; while(j>0&&event_less(key,events[j-1])) {events[j]=events[j-1];j--;} events[j]=key; }
    int active[MAX_M], ac=0; int64_t response[MAX_Q]={0};
    for(int z=0;z<ec;z++) {
        Event e=events[z];
        if(e.kind==0) { int k=0; while(k<ac&&active[k]!=e.id)k++; if(k==ac)return -1; for(;k+1<ac;k++)active[k]=active[k+1]; ac--; }
        else if(e.kind==1) { int k=0; while(k<ac&&edge_less(p,u,v,active[k],(int)e.id,e.x))k++; for(int h=ac;h>k;h--)active[h]=active[h-1];active[k]=(int)e.id;ac++; }
        else {
            int lo=0,hi=ac; while(lo<hi) {int mid=(lo+hi)/2;int64_t num,den;height(p,u,v,active[mid],e.x,&num,&den);if(num<qy[e.id]*den)lo=mid+1;else hi=mid;}
            if(lo<ac) {int64_t num,den;height(p,u,v,active[lo],e.x,&num,&den);if(num==qy[e.id]*den)response[e.id]=f+active[lo]+1;else if(lo>0&&face[active[lo-1]]>=0)response[e.id]=face[active[lo-1]]+1;}
            else if(lo>0&&face[active[lo-1]]>=0)response[e.id]=face[active[lo-1]]+1;
        }
    }
    int64_t result=0; for(int i=0;i<q;i++) result+=(int64_t)(i+1)*response[i]; return result;
}
