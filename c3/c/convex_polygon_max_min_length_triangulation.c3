module convex_polygon_max_min_length_triangulation;

const int MIN_N = 3;
const int MAX_N = 6;
const usz MAX_LENGTH = 14;

struct Point { long x; long y; }

fn long orient(Point a, Point b, Point c) {
    return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);
}
fn long distance_squared(Point a, Point b) {
    long dx=a.x-b.x, dy=a.y-b.y;
    return dx*dx+dy*dy;
}
fn int diagonal_bit(int n, int a, int b) {
    if (a>b) { int temporary=a; a=b; b=temporary; }
    int bit=0;
    for (int left=0;left<n;left++) for (int right=left+2;right<n;right++) {
        if (left==0 && right==n-1) continue;
        if (left==a && right==b) return bit;
        bit++;
    }
    return -1;
}
fn bool angle_at_least_sixty(Point p, Point q, Point r) {
    long ux=p.x-q.x, uy=p.y-q.y, vx=r.x-q.x, vy=r.y-q.y;
    long dot=ux*vx+uy*vy;
    if (dot<=0) return true;
    long norm_u=ux*ux+uy*uy, norm_v=vx*vx+vy*vy;
    return 4*dot*dot<=norm_u*norm_v;
}
fn long greedy(Point* points, int n) {
    int[MAX_N] next;
    for (int i=0;i<n;i++) next[i]=(i+1)%n;
    long shortest=513;
    for (int i=0;i<n;i++) {
        long edge=distance_squared(points[i],points[(i+1)%n]);
        if (edge<shortest) shortest=edge;
    }
    int active=n, p=0, q=next[0], r=next[q], steps=0;
    long diagonal_mask=0;
    while (active>3) {
        if (++steps>4*n) return -1;
        if (angle_at_least_sixty(points[p],points[q],points[r])) {
            long chord=distance_squared(points[p],points[r]);
            if (chord<shortest) shortest=chord;
            int bit=diagonal_bit(n,p,r);
            if (bit<0) return -1;
            diagonal_mask |= ((long)1)<<bit;
            next[p]=r;
            active--;
            q=r;
            r=next[r];
        } else {
            p=q;
            q=r;
            r=next[r];
        }
    }
    return shortest*512+diagonal_mask;
}

fn long convex_polygon_max_min_length_triangulation(long* input, usz length)
        @export("convex_polygon_max_min_length_triangulation") {
    if (input==null || length<1 || length>MAX_LENGTH) return -1;
    if (input[0]<MIN_N || input[0]>MAX_N) return -1;
    int n=(int)input[0];
    if (length!=(usz)(1+2*n)) return -1;
    Point[MAX_N] points;
    for (int i=0;i<n;i++) {
        points[i]=Point{input[1+2*i],input[2+2*i]};
        if (points[i].x < -8 || points[i].x > 8 || points[i].y < -8 || points[i].y > 8) return -1;
        for (int j=0;j<i;j++)
            if (points[i].x==points[j].x && points[i].y==points[j].y) return -1;
    }
    long area2=0;
    for (int i=0;i<n;i++) {
        int following=(i+1)%n;
        area2+=points[i].x*points[following].y-points[i].y*points[following].x;
    }
    if (area2<=0) return -1;
    for (int a=0;a<n;a++) for (int b=a+1;b<n;b++) for (int c=b+1;c<n;c++)
        if (orient(points[a],points[b],points[c])==0) return -1;
    for (int edge=0;edge<n;edge++) {
        int following=(edge+1)%n;
        for (int vertex=0;vertex<n;vertex++)
            if (vertex!=edge && vertex!=following && orient(points[edge],points[following],points[vertex])<=0) return -1;
    }
    return greedy(&points[0],n);
}
