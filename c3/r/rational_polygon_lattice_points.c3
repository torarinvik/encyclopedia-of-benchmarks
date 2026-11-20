module rational_polygon_lattice_points;

const usz MAX_N = 8;
const usz MAX_LENGTH = 19;
struct Point { long x; long y; }

fn long floor_div(long a, long b) {
    long q = a / b;
    long r = a % b;
    return q - (r < 0 ? 1 : 0);
}
fn long ceil_div(long a, long b) { return -floor_div(-a, b); }

fn long floor_sum(long n, long m, long a, long b) {
    long aq = floor_div(a, m), bq = floor_div(b, m);
    long answer = aq*n*(n-1)/2 + bq*n;
    a -= aq*m; b -= bq*m;
    while (true) {
        if (a >= m) { answer += (n-1)*n*(a/m)/2; a %= m; }
        if (b >= m) { answer += n*(b/m); b %= m; }
        long top = a*n+b;
        if (top < m) return answer;
        n = top/m; b = top%m;
        long t = m; m = a; a = t;
    }
}

fn long edge_chunk(long scale, Point a, long dx, long dy, long start, long columns) {
    if (columns <= 0) return 0;
    long aa=dy*scale, bb=a.y*dx-dy*a.x, den=scale*dx;
    if (den<0) { aa=-aa; bb=-bb; den=-den; }
    long base=aa*start+bb;
    if (dx>0) return -floor_sum(columns,den,aa,base);
    return -floor_sum(columns,den,-aa,-base)-columns;
}

fn bool strictly_inside(Point* p, long n, long scale, long x, long y) {
    long px=x*scale, py=y*scale;
    bool inside=false;
    for (long i=0; i<n; ++i) {
        Point a=p[i], b=p[(i+1)%n];
        long cross=(b.x-a.x)*(py-a.y)-(b.y-a.y)*(px-a.x);
        if (cross==0 && px >= (a.x<b.x?a.x:b.x) && px <= (a.x>b.x?a.x:b.x) &&
            py >= (a.y<b.y?a.y:b.y) && py <= (a.y>b.y?a.y:b.y)) return false;
        if ((a.y>py)!=(b.y>py)) {
            long dy=b.y-a.y, dx=b.x-a.x;
            long left=a.x*dy+(py-a.y)*dx, right=px*dy;
            if ((dy>0 && left>right) || (dy<0 && left<right)) inside=!inside;
        }
    }
    return inside;
}

fn long rational_polygon_lattice_points(long* input, usz length)
        @export("rational_polygon_lattice_points") {
    if (input == null || length < 2 || length > MAX_LENGTH) return -1;
    long scale=input[0], n=input[1];
    if (scale < 2 || scale > 8 || n < 3 || n > MAX_N || length != (usz)(2+2*n)) return -1;
    Point p[MAX_N]; bool fractional=false;
    for (usz i=0; i<(usz)n; ++i) {
        p[i].x=input[2+2*i]; p[i].y=input[3+2*i];
        if (p[i].x < -32 || p[i].x > 32 || p[i].y < -32 || p[i].y > 32) return -1;
        if (p[i].x < -4*scale || p[i].x > 4*scale || p[i].y < -4*scale || p[i].y > 4*scale) return -1;
        if (p[i].x%scale != 0 || p[i].y%scale != 0) fractional=true;
        for (usz j=0; j<i; ++j)
            if (p[i].x==p[j].x && p[i].y==p[j].y) return -1;
    }
    if (!fractional) return -1;
    long area2=0;
    for (usz i=0; i<(usz)n; ++i) {
        Point a=p[i], b=p[(i+1)%(usz)n]; area2 += a.x*b.y-a.y*b.x;
    }
    if (area2==0) return -1;
    long orientation=area2>0?1:-1;
    for (usz i=0; i<(usz)n; ++i) {
        Point a=p[i], b=p[(i+1)%(usz)n];
        for (usz j=0; j<(usz)n; ++j) {
            if (j==i || j==(i+1)%(usz)n) continue;
            Point c=p[j];
            long cross=(b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);
            if (cross*orientation<=0) return -1;
        }
    }
    long signed_count=0;
    for (usz i=0; i<(usz)n; ++i) {
        Point a=p[i], b=p[(i+1)%(usz)n];
        long dx=b.x-a.x, dy=b.y-a.y;
        if (dx==0) continue;
        long lo=a.x<b.x?a.x:b.x, hi=a.x>b.x?a.x:b.x;
        long start=ceil_div(lo,scale), columns=ceil_div(hi,scale)-start;
        long stop=start+columns, cursor=start;
        for (long col=start; col<stop; ++col) {
            bool event=false;
            for (usz k=0; k<(usz)n; ++k) if (p[k].x==col*scale) event=true;
            if (event) { signed_count+=edge_chunk(scale,a,dx,dy,cursor,col-cursor); cursor=col+1; }
        }
        signed_count+=edge_chunk(scale,a,dx,dy,cursor,stop-cursor);
    }
    for (usz i=0; i<(usz)n; ++i) {
        if (p[i].x%scale!=0) continue;
        bool first=true;
        for (usz j=0; j<i; ++j) if (p[j].x==p[i].x) first=false;
        if (!first) continue;
        long x=p[i].x/scale, count=0;
        for (long y=-4; y<=4; ++y) if (strictly_inside(p,n,scale,x,y)) count++;
        signed_count+=orientation*count;
    }
    long result=signed_count*orientation;
    return result>=0?result:-1;
}
