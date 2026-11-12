#include <stddef.h>
#include <stdint.h>
#include <limits.h>

enum { MAX_INPUT = 67, MAX_OUTPUT = 504, MAX_N = 32, MAX_M = 32, MAX_H = 63 };
typedef struct {
    const int64_t *concave, *arbitrary;
    size_t n, m, h;
    size_t y_min[MAX_H], y_max[MAX_H], x_min[MAX_N], x_max[MAX_N];
    int64_t result[MAX_H];
} Context;

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { output[offset+byte]=(uint8_t)(bits&255u); bits >>= 8; }
}

static void block_rows(Context *c, size_t x1, size_t x2, size_t y1, size_t y2,
                       size_t row1, size_t row2, size_t q1, size_t q2) {
    if (row1 > row2) return;
    size_t mid = row1 + (row2-row1)/2;
    size_t x = x1 + mid;
    int64_t best = INT64_MAX;
    size_t best_q = q1;
    for (size_t q=q1; q<=q2; ++q) {
        size_t y = y2-q;
        int64_t value = c->arbitrary[y] + c->concave[x-y];
        if (value < best) { best=value; best_q=q; }
    }
    if (best < c->result[x]) c->result[x] = best;
    if (row1 < mid) block_rows(c,x1,x2,y1,y2,row1,mid-1,q1,best_q);
    if (mid < row2) block_rows(c,x1,x2,y1,y2,mid+1,row2,best_q,q2);
}

static void scan_rectangle(Context *c, size_t x1, size_t x2, size_t y1, size_t y2) {
    for (size_t x=x1; x<=x2; ++x) {
        size_t low = c->y_min[x] > y1 ? c->y_min[x] : y1;
        size_t high = c->y_max[x] < y2 ? c->y_max[x] : y2;
        if (low > high) continue;
        for (size_t y=low; y<=high; ++y) {
            int64_t value=c->arbitrary[y]+c->concave[x-y];
            if (value<c->result[x]) c->result[x]=value;
        }
    }
}

static void partition(Context *c, size_t x1, size_t x2, size_t y1, size_t y2) {
    if (x1>x2 || y1>y2) return;
    if (c->y_max[x1]>=y2 && y1>=c->y_min[x2]) {
        block_rows(c,x1,x2,y1,y2,0,x2-x1,0,y2-y1);
        return;
    }
    if ((x2-x1)*(y2-y1)<1000) { scan_rectangle(c,x1,x2,y1,y2); return; }
    if (x2-x1>y2-y1) {
        size_t middle=(x1+x2)/2;
        size_t left_y2=c->y_max[middle]<y2?c->y_max[middle]:y2;
        if (y1<=left_y2) partition(c,x1,middle,y1,left_y2);
        size_t right_y1=c->y_min[middle]>y1?c->y_min[middle]:y1;
        if (right_y1<=y2) partition(c,middle+1,x2,right_y1,y2);
    } else {
        size_t middle=(y1+y2)/2;
        size_t left_x2=c->x_max[middle]<x2?c->x_max[middle]:x2;
        if (x1<=left_x2) partition(c,x1,left_x2,y1,middle);
        size_t right_x1=c->x_min[middle]>x1?c->x_min[middle]:x1;
        if (right_x1<=x2) partition(c,right_x1,x2,middle+1,y2);
    }
}

int64_t min_plus_convolution_concave_arbitrary(const int64_t *input, size_t length,
                                               uint8_t *output, size_t capacity) {
    if (input==NULL || length<4 || length>MAX_INPUT) return -1;
    int64_t n0=input[0],m0=input[1];
    if (n0<1 || n0>MAX_N || m0<1 || m0>MAX_M) return -1;
    size_t n=(size_t)n0,m=(size_t)m0;
    if (length!=2+n+m) return -1;
    const int64_t *concave=input+2,*arbitrary=input+2+n;
    for (size_t i=0;i<n+m;++i) if (input[2+i]<0 || input[2+i]>1000000000) return -1;
    for (size_t i=0;i+2<n;++i)
        if (concave[i+1]-concave[i] < concave[i+2]-concave[i+1]) return -1;
    size_t h=n+m-1,bytes=8*h;
    if (bytes>MAX_OUTPUT) return -1;
    if (output==NULL || capacity<bytes) return -2;
    Context c={0}; c.concave=concave; c.arbitrary=arbitrary; c.n=m; c.m=n; c.h=h;
    for (size_t x=0;x<h;++x) {
        c.y_min[x]=x>=n?x-n+1:0;
        c.y_max[x]=x<m?x:m-1;
        c.result[x]=INT64_MAX;
    }
    for (size_t y=0;y<m;++y) { c.x_min[y]=y; c.x_max[y]=n-1+y; }
    partition(&c,0,h-1,0,m-1);
    for (size_t i=0;i<h;++i) store_i64_le(output,8*i,c.result[i]);
    return (int64_t)bytes;
}
