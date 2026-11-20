// Independently authored draft; not compiled or run.
module minimum_enclosing_circle_incremental_boundary;
struct Point { long x, y; }
struct Circle { long x, y, den, radius2; }

fn long distance(Circle circle, Point point) {
    long dx = point.x*circle.den-circle.x, dy = point.y*circle.den-circle.y;
    return dx*dx+dy*dy;
}
fn Circle point_circle(Point p) { return (Circle){p.x,p.y,1,0}; }
fn Circle pair_circle(Point a, Point b) {
    Circle c = {a.x+b.x,a.y+b.y,2,0};
    c.radius2 = distance(c,a);
    return c;
}
fn Circle triple_circle(Point a, Point b, Point c) {
    long den = 2*(a.x*(b.y-c.y)+b.x*(c.y-a.y)+c.x*(a.y-b.y));
    if (den == 0) {
        Circle ab = pair_circle(a,b), ac = pair_circle(a,c), bc = pair_circle(b,c);
        if (ab.radius2 >= ac.radius2 && ab.radius2 >= bc.radius2) return ab;
        return ac.radius2 >= bc.radius2 ? ac : bc;
    }
    long aa = a.x*a.x+a.y*a.y, bb = b.x*b.x+b.y*b.y, cc = c.x*c.x+c.y*c.y;
    long x = aa*(b.y-c.y)+bb*(c.y-a.y)+cc*(a.y-b.y);
    long y = aa*(c.x-b.x)+bb*(a.x-c.x)+cc*(b.x-a.x);
    if (den < 0) { den = -den; x = -x; y = -y; }
    Circle result = {x,y,den,0};
    result.radius2 = distance(result,a);
    return result;
}

fn long minimum_enclosing_circle_incremental_boundary(long* input, usz length,
        char* output, usz capacity) @export("minimum_enclosing_circle_incremental_boundary") {
    if (input == null || length < 4 || length > 194 || input[0] < 1 || input[0] > 64) return -1;
    usz n = (usz)input[0];
    if (length != 1+3*n) return -1;
    Point[64] points = zeroed;
    usz[64] order = zeroed;
    bool[64] seen = zeroed;
    for (usz i = 0; i < n; i++) {
        long x = input[1+2*i], y = input[2+2*i];
        if (x < -100 || x > 100 || y < -100 || y > 100) return -1;
        points[i] = (Point){x,y};
    }
    for (usz i = 0; i < n; i++) {
        long v = input[1+2*n+i];
        if (v < 0 || v >= (long)n || seen[(usz)v]) return -1;
        order[i] = (usz)v; seen[order[i]] = true;
    }
    if (output == null || capacity < n) return -2;
    Circle circle = point_circle(points[order[0]]);
    for (usz i = 1; i < n; i++) {
        Point a = points[order[i]];
        if (distance(circle,a) <= circle.radius2) continue;
        circle = point_circle(a);
        for (usz j = 0; j < i; j++) {
            Point b = points[order[j]];
            if (distance(circle,b) <= circle.radius2) continue;
            circle = pair_circle(a,b);
            for (usz k = 0; k < j; k++) {
                Point c = points[order[k]];
                if (distance(circle,c) > circle.radius2) circle = triple_circle(a,b,c);
            }
        }
    }
    for (usz i = 0; i < n; i++) output[i] = distance(circle,points[i]) == circle.radius2 ? 1 : 0;
    return (long)n;
}
