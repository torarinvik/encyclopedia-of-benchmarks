#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_LENGTH = 19 };
typedef struct { int64_t x, y; } Point;

static int64_t floor_div(int64_t a, int64_t b) {
    int64_t q = a / b, r = a % b;
    return q - (r < 0 ? 1 : 0);
}

static int64_t ceil_div(int64_t a, int64_t b) {
    return -floor_div(-a, b);
}

static int64_t floor_sum(int64_t n, int64_t m, int64_t a, int64_t b) {
    int64_t aq = floor_div(a, m), bq = floor_div(b, m);
    int64_t answer = aq * n * (n - 1) / 2 + bq * n;
    a -= aq * m;
    b -= bq * m;
    for (;;) {
        if (a >= m) {
            answer += (n - 1) * n * (a / m) / 2;
            a %= m;
        }
        if (b >= m) {
            answer += n * (b / m);
            b %= m;
        }
        int64_t top = a * n + b;
        if (top < m) return answer;
        n = top / m;
        b = top % m;
        int64_t t = m; m = a; a = t;
    }
}

static int64_t edge_chunk(int64_t scale, Point a, int64_t dx, int64_t dy,
                          int64_t start, int64_t columns) {
    if (columns <= 0) return 0;
    int64_t aa = dy*scale, bb = a.y*dx-dy*a.x, den = scale*dx;
    if (den < 0) { aa = -aa; bb = -bb; den = -den; }
    int64_t base = aa*start+bb;
    if (dx > 0) return -floor_sum(columns,den,aa,base);
    return -floor_sum(columns,den,-aa,-base)-columns;
}

static int strictly_inside(Point *p, int64_t n, int64_t scale,
                           int64_t x, int64_t y) {
    int64_t px=x*scale, py=y*scale;
    int inside=0;
    for (int64_t i=0; i<n; ++i) {
        Point a=p[i], b=p[(i+1)%n];
        int64_t cross=(b.x-a.x)*(py-a.y)-(b.y-a.y)*(px-a.x);
        if (cross==0 && px>=(a.x<b.x?a.x:b.x) && px<=(a.x>b.x?a.x:b.x) &&
            py>=(a.y<b.y?a.y:b.y) && py<=(a.y>b.y?a.y:b.y)) return 0;
        if ((a.y>py)!=(b.y>py)) {
            int64_t dy=b.y-a.y, dx=b.x-a.x;
            int64_t left=a.x*dy+(py-a.y)*dx, right=px*dy;
            if ((dy>0 && left>right) || (dy<0 && left<right)) inside=!inside;
        }
    }
    return inside;
}

int64_t rational_polygon_lattice_points(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_LENGTH) return -1;
    int64_t scale = input[0], n = input[1];
    if (scale < 2 || scale > 8 || n < 3 || n > MAX_N || length != (size_t)(2 + 2*n)) return -1;
    Point p[MAX_N];
    int fractional = 0;
    for (int64_t i = 0; i < n; ++i) {
        p[i].x = input[2 + 2*i]; p[i].y = input[3 + 2*i];
        if (p[i].x < -32 || p[i].x > 32 || p[i].y < -32 || p[i].y > 32) return -1;
        if (p[i].x < -4*scale || p[i].x > 4*scale || p[i].y < -4*scale || p[i].y > 4*scale) return -1;
        if (p[i].x % scale != 0 || p[i].y % scale != 0) fractional = 1;
        for (int64_t j = 0; j < i; ++j)
            if (p[i].x == p[j].x && p[i].y == p[j].y) return -1;
    }
    if (!fractional) return -1;
    int64_t area2 = 0;
    for (int64_t i = 0; i < n; ++i) {
        Point a = p[i], b = p[(i + 1) % n];
        area2 += a.x*b.y - a.y*b.x;
    }
    if (area2 == 0) return -1;
    int64_t orientation = area2 > 0 ? 1 : -1;
    for (int64_t i = 0; i < n; ++i) {
        Point a = p[i], b = p[(i + 1) % n];
        for (int64_t j = 0; j < n; ++j) {
            if (j == i || j == (i + 1) % n) continue;
            Point c = p[j];
            int64_t cross = (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x);
            if (cross * orientation <= 0) return -1;
        }
    }
    int64_t signed_count = 0;
    for (int64_t i = 0; i < n; ++i) {
        Point a = p[i], b = p[(i + 1) % n];
        int64_t dx = b.x-a.x, dy = b.y-a.y;
        if (dx == 0) continue;
        int64_t lo = a.x < b.x ? a.x : b.x;
        int64_t hi = a.x > b.x ? a.x : b.x;
        int64_t start = ceil_div(lo, scale), stop = ceil_div(hi, scale);
        int64_t cursor = start;
        for (int64_t col=start; col<stop; ++col) {
            int event=0;
            for (int64_t k=0; k<n; ++k) if (p[k].x==col*scale) event=1;
            if (event) {
                signed_count += edge_chunk(scale,a,dx,dy,cursor,col-cursor);
                cursor=col+1;
            }
        }
        signed_count += edge_chunk(scale,a,dx,dy,cursor,stop-cursor);
    }
    for (int64_t i=0; i<n; ++i) {
        if (p[i].x%scale != 0) continue;
        int first=1;
        for (int64_t j=0; j<i; ++j) if (p[j].x==p[i].x) first=0;
        if (!first) continue;
        int64_t x=p[i].x/scale, count=0;
        for (int64_t y=-4; y<=4; ++y) count += strictly_inside(p,n,scale,x,y);
        signed_count += orientation*count;
    }
    int64_t result = signed_count * orientation;
    return result >= 0 ? result : -1;
}
