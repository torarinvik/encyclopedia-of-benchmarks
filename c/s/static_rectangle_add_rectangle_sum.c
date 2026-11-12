#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_Q 32
#define MAX_COORDS (2 * (MAX_N + MAX_Q))
#define STRIDE (MAX_COORDS + 1)
#define MOD INT64_C(998244353)

static size_t lower_bound_i64(const int64_t a[MAX_COORDS], size_t n, int64_t x) {
    size_t lo = 0, hi = n;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (a[mid] < x) lo = mid + 1;
        else hi = mid;
    }
    return lo;
}

static void sort_unique(int64_t a[MAX_COORDS], size_t *n) {
    for (size_t i = 1; i < *n; ++i) {
        int64_t value = a[i];
        size_t j = i;
        while (j && a[j - 1] > value) { a[j] = a[j - 1]; --j; }
        a[j] = value;
    }
    size_t out = 0;
    for (size_t i = 0; i < *n; ++i)
        if (!out || a[i] != a[out - 1]) a[out++] = a[i];
    *n = out;
}

static void write_i64_le(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) out[at + i] = (uint8_t)(bits >> (8 * i));
}

int64_t static_rectangle_add_rectangle_sum(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 291) return -1;
    int64_t n64 = input[0], q64 = input[1];
    if (n64 < 1 || n64 > MAX_N || q64 < 0 || q64 > MAX_Q) return -1;
    size_t n = (size_t)n64, q = (size_t)q64;
    if (length != 2 + 5 * n + 4 * q) return -1;

    int64_t ul[MAX_N], ud[MAX_N], ur[MAX_N], uu[MAX_N], uw[MAX_N];
    int64_t ql[MAX_Q], qd[MAX_Q], qr[MAX_Q], qu[MAX_Q];
    int64_t xs[MAX_COORDS], ys[MAX_COORDS];
    size_t nx = 0, ny = 0, off = 2;
    for (size_t i = 0; i < n; ++i) {
        ul[i]=input[off]; ud[i]=input[off+1]; ur[i]=input[off+2];
        uu[i]=input[off+3]; uw[i]=input[off+4]; off+=5;
        if (ul[i] < 0 || ul[i] >= ur[i] || ur[i] > 1000000 ||
            ud[i] < 0 || ud[i] >= uu[i] || uu[i] > 1000000 ||
            uw[i] < 0 || uw[i] >= MOD) return -1;
        xs[nx++]=ul[i]; xs[nx++]=ur[i]; ys[ny++]=ud[i]; ys[ny++]=uu[i];
    }
    for (size_t i = 0; i < q; ++i) {
        ql[i]=input[off]; qd[i]=input[off+1]; qr[i]=input[off+2]; qu[i]=input[off+3]; off+=4;
        if (ql[i] < 0 || ql[i] >= qr[i] || qr[i] > 1000000 ||
            qd[i] < 0 || qd[i] >= qu[i] || qu[i] > 1000000) return -1;
        xs[nx++]=ql[i]; xs[nx++]=qr[i]; ys[ny++]=qd[i]; ys[ny++]=qu[i];
    }
    sort_unique(xs, &nx); sort_unique(ys, &ny);

    int64_t diff[MAX_COORDS * MAX_COORDS] = {0};
    int64_t prefix[STRIDE * STRIDE] = {0};
    for (size_t k = 0; k < n; ++k) {
        size_t x0=lower_bound_i64(xs,nx,ul[k]), x1=lower_bound_i64(xs,nx,ur[k]);
        size_t y0=lower_bound_i64(ys,ny,ud[k]), y1=lower_bound_i64(ys,ny,uu[k]);
        diff[x0*MAX_COORDS+y0]+=uw[k]; diff[x1*MAX_COORDS+y0]-=uw[k];
        diff[x0*MAX_COORDS+y1]-=uw[k]; diff[x1*MAX_COORDS+y1]+=uw[k];
    }
    for (size_t i = 0; i < nx; ++i) for (size_t j = 0; j < ny; ++j) {
        size_t at=i*MAX_COORDS+j; int64_t value=diff[at];
        if (i) value+=diff[(i-1)*MAX_COORDS+j];
        if (j) value+=diff[i*MAX_COORDS+j-1];
        if (i && j) value-=diff[(i-1)*MAX_COORDS+j-1];
        diff[at]=value;
    }
    for (size_t i = 0; i + 1 < nx; ++i) for (size_t j = 0; j + 1 < ny; ++j) {
        int64_t value=diff[i*MAX_COORDS+j] % MOD;
        int64_t dx=(xs[i+1]-xs[i]) % MOD, dy=(ys[j+1]-ys[j]) % MOD;
        int64_t cell=value * (dx * dy % MOD) % MOD;
        size_t at=(i+1)*STRIDE+(j+1);
        int64_t sum=cell+prefix[i*STRIDE+j+1]+prefix[(i+1)*STRIDE+j]-prefix[i*STRIDE+j];
        sum%=MOD; if (sum<0) sum+=MOD; prefix[at]=sum;
    }
    int64_t answers[MAX_Q];
    for (size_t k=0;k<q;++k) {
        size_t x0=lower_bound_i64(xs,nx,ql[k]), x1=lower_bound_i64(xs,nx,qr[k]);
        size_t y0=lower_bound_i64(ys,ny,qd[k]), y1=lower_bound_i64(ys,ny,qu[k]);
        int64_t value=prefix[x1*STRIDE+y1]-prefix[x0*STRIDE+y1]
                     -prefix[x1*STRIDE+y0]+prefix[x0*STRIDE+y0];
        value%=MOD; if (value<0) value+=MOD; answers[k]=value;
    }
    size_t bytes=8*q;
    if (!output || capacity<bytes) return -2;
    for (size_t k=0;k<q;++k) write_i64_le(output,8*k,answers[k]);
    return (int64_t)bytes;
}
