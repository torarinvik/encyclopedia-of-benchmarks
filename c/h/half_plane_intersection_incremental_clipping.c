/* Independently authored draft; not compiled or run. */
#include <stddef.h>
#include <stdint.h>

typedef struct { int64_t a,b,c; } ClipLine;
typedef struct { int64_t x,y,den; int incoming; } ClipVertex;

static int64_t clip_abs(int64_t a) { return a < 0 ? -a : a; }
static int64_t clip_gcd(int64_t a, int64_t b) {
    a = clip_abs(a); b = clip_abs(b);
    while (b) { int64_t r = a%b; a = b; b = r; }
    return a;
}
static int clip_intersect(ClipLine a, ClipLine b, ClipVertex *p) {
    int64_t d = a.a*b.b-b.a*a.b;
    if (!d) return 0;
    int64_t x = a.c*b.b-a.b*b.c, y = a.a*b.c-a.c*b.a;
    if (d < 0) { d = -d; x = -x; y = -y; }
    int64_t g = clip_gcd(clip_gcd(x,y),d);
    p->x=x/g; p->y=y/g; p->den=d/g;
    return 1;
}
static int64_t clip_side(ClipLine l, ClipVertex p) {
    return l.a*p.x+l.b*p.y-l.c*p.den;
}
static int clip_same(ClipVertex a, ClipVertex b) {
    return a.x*b.den == b.x*a.den && a.y*b.den == b.y*a.den;
}
static int64_t clip_turn(ClipVertex a, ClipVertex b, ClipVertex c) {
    int64_t dx1=b.x*a.den-a.x*b.den, dy1=b.y*a.den-a.y*b.den;
    int64_t dx2=c.x*b.den-b.x*c.den, dy2=c.y*b.den-b.y*c.den;
    return dx1*dy2-dy1*dx2;
}
static void clip_append(ClipVertex *out, int *count, ClipVertex p) {
    if (!*count || !clip_same(out[*count-1],p)) out[(*count)++] = p;
}
static void clip_put(uint8_t *output, size_t *offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (int i=0;i<8;++i) output[(*offset)++] = (uint8_t)(bits >> (8*i));
}

int64_t half_plane_intersection_incremental_clipping(const int64_t *input,
        size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 1 || length > 38 || input[0] < 0 || input[0] > 12) return -1;
    int n=(int)input[0];
    if (length != 1+3*(size_t)n) return -1;
    ClipLine lines[16] = {{-1,0,256},{0,-1,256},{1,0,256},{0,1,256}};
    for (int i=0;i<n;++i) {
        int64_t a=input[1+3*i], b=input[2+3*i], c=input[3+3*i];
        if (a < -16 || a > 16 || b < -16 || b > 16 || c < -128 || c > 128
                || (!a && !b) || clip_gcd(a,b) != 1) return -1;
        lines[4+i]=(ClipLine){a,b,c};
    }
    ClipVertex polygon[32] = {{-256,-256,1,0},{256,-256,1,1},
                              {256,256,1,2},{-256,256,1,3}};
    int count=4;
    for (int line=4;line<4+n && count>=3;++line) {
        ClipVertex next[32]; int used=0;
        for (int i=0;i<count;++i) {
            ClipVertex s=polygon[(i+count-1)%count], e=polygon[i], intersection;
            int s_in=clip_side(lines[line],s)<=0, e_in=clip_side(lines[line],e)<=0;
            if (s_in != e_in) {
                if (!clip_intersect(lines[e.incoming],lines[line],&intersection)) return -1;
                intersection.incoming = s_in ? e.incoming : line;
                clip_append(next,&used,intersection);
            }
            if (e_in) clip_append(next,&used,e);
        }
        if (used>1 && clip_same(next[0],next[used-1])) {
            next[0].incoming=next[used-1].incoming; --used;
        }
        count=used;
        for (int i=0;i<count;++i) polygon[i]=next[i];
        int noncollinear=0;
        for (int i=0;i<count && count>=3;++i)
            if (clip_turn(polygon[i],polygon[(i+1)%count],polygon[(i+2)%count]) != 0) noncollinear=1;
        if (!noncollinear) count=0;
    }
    int changed=1;
    while (changed && count>=3) {
        changed=0;
        for (int i=0;i<count;++i) {
            if (clip_turn(polygon[(i+count-1)%count],polygon[i],polygon[(i+1)%count])==0) {
                for (int j=i;j+1<count;++j) polygon[j]=polygon[j+1];
                --count; changed=1; break;
            }
        }
    }
    if (count<3) count=0;
    int first=0;
    for (int i=1;i<count;++i) {
        int64_t yi=polygon[i].y*polygon[first].den, yf=polygon[first].y*polygon[i].den;
        if (yi<yf || (yi==yf && polygon[i].x*polygon[first].den < polygon[first].x*polygon[i].den)) first=i;
    }
    size_t needed=(size_t)(1+4*count)*8;
    if (!output || capacity<needed) return -2;
    size_t offset=0; clip_put(output,&offset,count);
    for (int i=0;i<count;++i) {
        ClipVertex p=polygon[(first+i)%count];
        int64_t gx=clip_gcd(p.x,p.den), gy=clip_gcd(p.y,p.den);
        clip_put(output,&offset,p.x/gx); clip_put(output,&offset,p.den/gx);
        clip_put(output,&offset,p.y/gy); clip_put(output,&offset,p.den/gy);
    }
    return (int64_t)needed;
}
