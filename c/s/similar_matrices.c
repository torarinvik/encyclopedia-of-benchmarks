#include <stddef.h>
#include <stdint.h>

#define SM_MAX_VALUES 19
#define SM_MAX_N 3

static int64_t sm_det3(const int64_t *m)
{
    return m[0] * (m[4] * m[8] - m[5] * m[7])
         - m[1] * (m[3] * m[8] - m[5] * m[6])
         + m[2] * (m[3] * m[7] - m[4] * m[6]);
}

static void sm_charpoly(const int64_t *m, int n, int64_t *a, int64_t *b, int64_t *c)
{
    int64_t trace = 0;
    for (int i = 0; i < n; ++i) trace += m[i * n + i];
    *a = -trace;
    *b = 0;
    *c = 0;
    if (n == 2) {
        *b = m[0] * m[3] - m[1] * m[2];
    } else if (n == 3) {
        *b = (m[0] * m[4] - m[1] * m[3])
           + (m[0] * m[8] - m[2] * m[6])
           + (m[4] * m[8] - m[5] * m[7]);
        *c = -sm_det3(m);
    }
}

static int64_t sm_disc3(int64_t a, int64_t b, int64_t c)
{
    return a*a*b*b - 4*b*b*b - 4*a*a*a*c - 27*c*c + 18*a*b*c;
}

/* Rank of a matrix known to be singular. */
static int sm_rank_singular(const int64_t *m, int n)
{
    for (int r0 = 0; r0 < n; ++r0) {
        for (int r1 = r0 + 1; r1 < n; ++r1) {
            for (int c0 = 0; c0 < n; ++c0) {
                for (int c1 = c0 + 1; c1 < n; ++c1) {
                    int64_t minor = m[r0*n+c0] * m[r1*n+c1] - m[r0*n+c1] * m[r1*n+c0];
                    if (minor != 0) return 2;
                }
            }
        }
    }
    for (int i = 0; i < n*n; ++i) if (m[i] != 0) return 1;
    return 0;
}

static void sm_shifted(const int64_t *m, int n, int64_t numerator, int64_t denominator,
                       int64_t *out)
{
    for (int i = 0; i < n*n; ++i) out[i] = denominator * m[i];
    for (int i = 0; i < n; ++i) out[i*n+i] -= numerator;
}

static void sm_multiply(const int64_t *a, const int64_t *b, int n, int64_t *out)
{
    for (int row = 0; row < n; ++row) {
        for (int col = 0; col < n; ++col) {
            int64_t value = 0;
            for (int k = 0; k < n; ++k) value += a[row*n+k] * b[k*n+col];
            out[row*n+col] = value;
        }
    }
}

static int sm_similar(const int64_t *a, const int64_t *b, int n)
{
    int64_t aa, ab, ac, ba, bb, bc;
    sm_charpoly(a, n, &aa, &ab, &ac);
    sm_charpoly(b, n, &ba, &bb, &bc);
    if (aa != ba || ab != bb || ac != bc) return 0;
    if (n == 1) return 1;
    if (n == 2) {
        if (aa*aa - 4*ab != 0) return 1;
        int64_t da[9] = {0}, db[9] = {0};
        sm_shifted(a, n, -aa, 2, da);
        sm_shifted(b, n, -aa, 2, db);
        return sm_rank_singular(da, n) == sm_rank_singular(db, n);
    }
    if (sm_disc3(aa, ab, ac) != 0) return 1;
    const int64_t q = aa*aa - 3*ab;
    int64_t da[9] = {0}, db[9] = {0};
    if (q == 0) {
        sm_shifted(a, n, -aa, 3, da);
        sm_shifted(b, n, -aa, 3, db);
        if (sm_rank_singular(da, n) != sm_rank_singular(db, n)) return 0;
        int64_t da2[9] = {0}, db2[9] = {0};
        sm_multiply(da, da, n, da2);
        sm_multiply(db, db, n, db2);
        return sm_rank_singular(da2, n) == sm_rank_singular(db2, n);
    }
    const int64_t numerator = 9*ac - aa*ab;
    const int64_t denominator = 2*q;
    sm_shifted(a, n, numerator, denominator, da);
    sm_shifted(b, n, numerator, denominator, db);
    return sm_rank_singular(da, n) == sm_rank_singular(db, n);
}

int64_t similar_matrices(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > SM_MAX_VALUES) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > SM_MAX_N) return -1;
    const int n = (int)n_value;
    if (length != (size_t)(1 + 2*n*n)) return -1;
    int64_t a[9] = {0}, b[9] = {0};
    const int matrix_size = n*n;
    for (int i = 0; i < 2*matrix_size; ++i) {
        if (input[1+i] < -5 || input[1+i] > 5) return -1;
    }
    for (int i = 0; i < matrix_size; ++i) {
        a[i] = input[1+i];
        b[i] = input[1+matrix_size+i];
    }
    return sm_similar(a, b, n);
}
