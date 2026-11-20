/* Independently authored draft; not compiled or run. */
#include <stddef.h>
#include <stdint.h>

enum { SCALE = 32768, MAX_LINES = 16 };
typedef struct { int64_t a,b,c,norm; } Line;
typedef struct { int64_t x,y,den; } Point;

static int64_t abs64(int64_t x) { return x < 0 ? -x : x; }
static int64_t gcd64(int64_t a,int64_t b) {
    a=abs64(a); b=abs64(b);
    while (b) { int64_t r=a%b; a=b; b=r; }
    return a;
}
static int half(Line l) { return l.b>0 || (l.b==0 && l.a>=0) ? 0 : 1; }
static int before(Line a,Line b) {
    int ha=half(a), hb=half(b);
    if (ha!=hb) return ha<hb;
    int64_t cross=a.a*b.b-a.b*b.a;
    if (cross) return cross>0;
    return a.c<b.c;
}
static void sort_lines(Line *lines,int count) {
    Line scratch[MAX_LINES];
    for (int width=1;width<count;width*=2) {
        for (int start=0;start<count;start+=2*width) {
            int middle=start+width<count ? start+width : count;
            int end=start+2*width<count ? start+2*width : count;
            int i=start,j=middle,k=start;
            while (i<middle && j<end)
                scratch[k++]=before(lines[j],lines[i]) ? lines[j++] : lines[i++];
            while (i<middle) scratch[k++]=lines[i++];
            while (j<end) scratch[k++]=lines[j++];
        }
        for (int i=0;i<count;++i) lines[i]=scratch[i];
    }
}
static int intersect(Line a,Line b,Point *p) {
    int64_t d=a.a*b.b-b.a*a.b;
    if (!d) return 0;
    int64_t x=a.c*b.b-a.b*b.c, y=a.a*b.c-a.c*b.a;
    if (d<0) { d=-d; x=-x; y=-y; }
    p->x=x; p->y=y; p->den=d;
    return 1;
}
static int outside(Line h,Point p) { return h.a*p.x+h.b*p.y>h.c*p.den; }

/* Input normals have already been sorted; the radius shift preserves order. */
static int feasible(const Line *base,int count,int radius) {
    Line queue[MAX_LINES]; int head=0,tail=0;
    for (int i=0;i<count;++i) {
        Line h=base[i];
        h.c=h.c*SCALE-(radius*SCALE-1)*h.norm;
        if (tail>head && queue[tail-1].a==h.a && queue[tail-1].b==h.b) {
            if (h.c>=queue[tail-1].c) continue;
            --tail;
        }
        Point p;
        while (tail-head>1 && intersect(queue[tail-2],queue[tail-1],&p) && outside(h,p)) --tail;
        while (tail-head>1 && intersect(queue[head],queue[head+1],&p) && outside(h,p)) ++head;
        if (tail>head && queue[tail-1].a*h.b-queue[tail-1].b*h.a==0) return 0;
        queue[tail++]=h;
    }
    Point p;
    while (tail-head>2 && intersect(queue[tail-2],queue[tail-1],&p) && outside(queue[head],p)) --tail;
    while (tail-head>2 && intersect(queue[head],queue[head+1],&p) && outside(queue[tail-1],p)) ++head;
    if (tail-head<3) return 0;
    for (int i=head;i<tail;++i)
        if (!intersect(queue[i],queue[i+1==tail ? head : i+1],&p)) return 0;
    return 1;
}

int64_t convex_polygon_integer_inradius(const int64_t *values,size_t length) {
    if (!values || length<1 || length>38 || values[0]<0 || values[0]>12) return -1;
    int n=(int)values[0];
    if (length!=(size_t)(1+3*n)) return -1;
    Line lines[MAX_LINES];
    for (int i=0;i<n;++i) {
        int64_t a=values[1+3*i],b=values[2+3*i],c=values[3+3*i];
        if (a < -15 || a > 15 || b < -15 || b > 15 || c < -128 || c > 128) return -1;
        int64_t squared=a*a+b*b, norm=0;
        while (norm*norm<squared) ++norm;
        if (!norm || norm*norm!=squared || gcd64(a,b)!=1) return -1;
        lines[i]=(Line){a,b,c,norm};
    }
    lines[n++]=(Line){1,0,256,1}; lines[n++]=(Line){0,1,256,1};
    lines[n++]=(Line){-1,0,256,1}; lines[n++]=(Line){0,-1,256,1};
    sort_lines(lines,n);
    if (!feasible(lines,n,0)) return -2;
    int low=0,high=257;
    while (high-low>1) {
        int mid=(low+high)/2;
        if (feasible(lines,n,mid)) low=mid; else high=mid;
    }
    return low;
}
