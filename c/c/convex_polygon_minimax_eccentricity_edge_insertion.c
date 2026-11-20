#include <stddef.h>
#include <stdint.h>

enum { MIN_N = 3, MAX_N = 6, MAX_LEN = 14, MAX_TRI = 4, MAX_ALL = 14, MAX_DIAG = 9, MAX_TRIPLES = 20 };
typedef struct { int64_t x, y; } Point;
typedef struct { int a, b, c; } Triangle;
typedef struct { Triangle triangles[MAX_TRI]; int count; uint64_t edges; } Triangulation;
typedef struct { int64_t num, den; } Fraction;
typedef struct { Fraction maximum; uint64_t worst; } Metrics;

static int64_t orient(Point a, Point b, Point c) {
    return (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x);
}
static int64_t abs64(int64_t x) { return x < 0 ? -x : x; }
static int64_t gcd64(int64_t a, int64_t b) {
    while (b) { int64_t r = a % b; a = b; b = r; }
    return a;
}
static Fraction fraction(int64_t num, int64_t den) {
    int64_t d = gcd64(num, den);
    return (Fraction){num/d, den/d};
}
static int cmp(Fraction a, Fraction b) {
    int64_t x = a.num*b.den, y = b.num*a.den;
    return x < y ? -1 : x > y ? 1 : 0;
}
static uint64_t edge_bit(int a, int b) {
    int lo = a < b ? a : b, hi = a < b ? b : a;
    return UINT64_C(1) << (lo*MAX_N + hi);
}
static int boundary_edge(int a, int b, int n) {
    int lo = a < b ? a : b, hi = a < b ? b : a;
    return hi == lo + 1 || (lo == 0 && hi == n - 1);
}
static int proper_cross(Point p[MAX_N], int a, int b, int c, int d) {
    return orient(p[a],p[b],p[c])*orient(p[a],p[b],p[d]) < 0
        && orient(p[c],p[d],p[a])*orient(p[c],p[d],p[b]) < 0;
}
static int inside_triangle(Point p[MAX_N], Triangle t, int v) {
    int64_t direction = orient(p[t.a],p[t.b],p[t.c]);
    return orient(p[t.a],p[t.b],p[v])*direction > 0
        && orient(p[t.b],p[t.c],p[v])*direction > 0
        && orient(p[t.c],p[t.a],p[v])*direction > 0;
}
static int has_edge(uint64_t edges, int a, int b) { return (edges & edge_bit(a,b)) != 0; }

static Fraction triangle_score(Point p[MAX_N], Triangle t, int64_t sides[3]) {
    Point a=p[t.a], b=p[t.b], c=p[t.c];
    sides[0]=(b.x-c.x)*(b.x-c.x)+(b.y-c.y)*(b.y-c.y);
    sides[1]=(c.x-a.x)*(c.x-a.x)+(c.y-a.y)*(c.y-a.y);
    sides[2]=(a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y);
    int largest=0;
    if (sides[1]>sides[largest]) largest=1;
    if (sides[2]>sides[largest]) largest=2;
    int64_t other=sides[0]+sides[1]+sides[2]-sides[largest];
    if (sides[largest] <= other) return (Fraction){0,1};
    int64_t area=abs64(orient(a,b,c));
    int64_t difference=sides[largest]-other;
    return fraction(sides[largest]*difference*difference,16*area*area);
}

static int triangle_id(int a, int b, int c, int n) {
    int id=0;
    for (int x=0;x<n;x++) for (int y=x+1;y<n;y++) for (int z=y+1;z<n;z++) {
        if (x==a && y==b && z==c) return id;
        id++;
    }
    return 0;
}
static Metrics evaluate(Point p[MAX_N], int n, Triangulation t) {
    Metrics m={(Fraction){0,1},0};
    for (int i=0;i<t.count;i++) {
        int64_t sides[3];
        Fraction s=triangle_score(p,t.triangles[i],sides);
        int c=cmp(s,m.maximum);
        uint64_t bit=UINT64_C(1)<<triangle_id(t.triangles[i].a,t.triangles[i].b,t.triangles[i].c,n);
        if (c>0) { m.maximum=s; m.worst=bit; }
        else if (c==0) m.worst|=bit;
    }
    return m;
}
static int improves(Metrics a, Metrics b) {
    int c=cmp(a.maximum,b.maximum);
    return c<0 || (c==0 && a.worst!=b.worst && (a.worst & b.worst)==a.worst);
}
static int popcount64(uint64_t x) { int n=0; while(x) { x &= x-1; n++; } return n; }
static int preferable(Metrics a, Metrics b) {
    int c=cmp(a.maximum,b.maximum);
    if (c!=0) return c<0;
    int pa=popcount64(a.worst), pb=popcount64(b.worst);
    return pa!=pb ? pa<pb : a.worst<b.worst;
}

static int enumerate(Point p[MAX_N], int n, Triangulation out[MAX_ALL]) {
    int da[MAX_DIAG], db[MAX_DIAG], m=0;
    for (int a=0;a<n;a++) for (int b=a+2;b<n;b++) {
        if (a==0 && b==n-1) continue;
        da[m]=a; db[m]=b; m++;
    }
    uint64_t boundary=0;
    for (int a=0;a<n;a++) boundary|=edge_bit(a,(a+1)%n);
    int total=0;
    for (int mask=0;mask<(1<<m);mask++) {
        int count=0;
        for (int i=0;i<m;i++) if ((mask>>i)&1) count++;
        if (count!=n-3) continue;
        int crossing=0;
        for (int i=0;i<m && !crossing;i++) if ((mask>>i)&1)
            for (int j=i+1;j<m;j++) if ((mask>>j)&1 && proper_cross(p,da[i],db[i],da[j],db[j])) { crossing=1; break; }
        if (crossing) continue;
        uint64_t edges=boundary;
        for (int i=0;i<m;i++) if ((mask>>i)&1) edges|=edge_bit(da[i],db[i]);
        Triangle faces[MAX_TRI];
        int face_count=0;
        for (int a=0;a<n;a++) for (int b=a+1;b<n;b++) for (int c=b+1;c<n;c++) {
            if (!has_edge(edges,a,b) || !has_edge(edges,b,c) || !has_edge(edges,c,a)) continue;
            int contains=0;
            for (int v=0;v<n;v++) if (v!=a && v!=b && v!=c && inside_triangle(p,(Triangle){a,b,c},v)) { contains=1; break; }
            if (!contains && face_count<MAX_TRI) faces[face_count++]=(Triangle){a,b,c};
        }
        if (face_count==n-2 && total<MAX_ALL) {
            out[total].count=face_count; out[total].edges=edges;
            for (int i=0;i<face_count;i++) out[total].triangles[i]=faces[i];
            total++;
        }
    }
    return total;
}

static int rank_score(Point p[MAX_N], int n, Fraction target) {
    Fraction seen[MAX_TRIPLES]; int count=0;
    for (int a=0;a<n;a++) for (int b=a+1;b<n;b++) for (int c=b+1;c<n;c++) {
        int64_t sides[3];
        Fraction s=triangle_score(p,(Triangle){a,b,c},sides);
        if (cmp(s,target)>=0) continue;
        int duplicate=0;
        for (int i=0;i<count;i++) if (cmp(s,seen[i])==0) { duplicate=1; break; }
        if (!duplicate) seen[count++]=s;
    }
    return count+1;
}

static int64_t solve(Point p[MAX_N], int n) {
    Triangulation all[MAX_ALL]; int total=enumerate(p,n,all);
    Triangulation fan={.count=0,.edges=0};
    for (int k=1;k<n-1;k++) fan.triangles[fan.count++]=(Triangle){0,k,k+1};
    for (int a=0;a<n;a++) fan.edges|=edge_bit(a,(a+1)%n);
    for (int k=2;k<n-1;k++) fan.edges|=edge_bit(0,k);
    int current_index=-1;
    for (int i=0;i<total;i++) if (all[i].edges==fan.edges) { current_index=i; break; }
    if (current_index<0) return -1;
    Triangulation current=all[current_index]; Metrics current_metrics=evaluate(p,n,current);
    for (int step=0;step<MAX_ALL;step++) {
        int changed=0;
        for (int ti=0;ti<current.count && !changed;ti++) {
            Triangle t=current.triangles[ti]; int64_t sides[3];
            Fraction score=triangle_score(p,t,sides);
            if (cmp(score,current_metrics.maximum)!=0 || score.num==0) continue;
            int largest=0; if (sides[1]>sides[largest]) largest=1; if (sides[2]>sides[largest]) largest=2;
            int vertices[3]={t.a,t.b,t.c};
            for (int ap=0;ap<3 && !changed;ap++) {
                if (sides[ap]!=sides[largest]) continue;
                int q=vertices[ap], opposite[2], used=0;
                for (int k=0;k<3;k++) if (k!=ap) opposite[used++]=vertices[k];
                for (int s=0;s<n && !changed;s++) {
                    uint64_t new_edge=edge_bit(q,s);
                    if (s==q || (current.edges&new_edge) || !proper_cross(p,q,s,opposite[0],opposite[1])) continue;
                    uint64_t retained=current.edges;
                    for (int u=0;u<n;u++) for (int v=u+1;v<n;v++) {
                        uint64_t bit=edge_bit(u,v);
                        if ((retained&bit) && proper_cross(p,q,s,u,v)) retained&=~bit;
                    }
                    int selected=-1; Metrics selected_metrics={{0,1},0};
                    for (int ci=0;ci<total;ci++) {
                        if (!(all[ci].edges&new_edge) || (all[ci].edges&retained)!=retained) continue;
                        Metrics candidate=evaluate(p,n,all[ci]);
                        if (!improves(candidate,current_metrics)) continue;
                        if (selected<0 || preferable(candidate,selected_metrics)) { selected=ci; selected_metrics=candidate; }
                    }
                    if (selected>=0) { current=all[selected]; current_metrics=selected_metrics; changed=1; }
                }
            }
        }
        if (!changed) break;
    }
    return rank_score(p,n,current_metrics.maximum);
}

int64_t convex_polygon_minimax_eccentricity_edge_insertion(const int64_t *input, size_t length) {
    if (input==NULL || length<1 || length>MAX_LEN || input[0]<MIN_N || input[0]>MAX_N) return -1;
    int n=(int)input[0];
    if (length!=(size_t)(1+2*n)) return -1;
    Point p[MAX_N];
    for (int i=0;i<n;i++) {
        p[i]=(Point){input[1+2*i],input[2+2*i]};
        if (p[i].x < -4 || p[i].x > 4 || p[i].y < -4 || p[i].y > 4) return -1;
        for (int j=0;j<i;j++) if (p[i].x==p[j].x && p[i].y==p[j].y) return -1;
    }
    int64_t area2=0;
    for (int i=0;i<n;i++) { int j=(i+1)%n; area2+=p[i].x*p[j].y-p[i].y*p[j].x; }
    if (area2==0) return -1;
    int orientation=area2>0 ? 1 : -1;
    for (int a=0;a<n;a++) for (int b=a+1;b<n;b++) for (int c=b+1;c<n;c++)
        if (orient(p[a],p[b],p[c])==0) return -1;
    for (int edge=0;edge<n;edge++) {
        int next=(edge+1)%n;
        for (int v=0;v<n;v++) if (v!=edge && v!=next && orientation*orient(p[edge],p[next],p[v])<=0) return -1;
    }
    return solve(p,n);
}
