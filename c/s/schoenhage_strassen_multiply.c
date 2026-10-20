/* Fresh bounded port based on NyaanNyaan's CC0 radix-2 Schönhage-Strassen method. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define SS_LIMBS 513
#define SS_INPUT_LENGTH (1 + 2 * SS_LIMBS)
#define SS_OUTPUT_BYTES 129
#define SS_PADDED 2048
#define SS_SCRATCH 4096

static void ss_reset(int64_t *a, int n) {
    for (int i = 0; i < n; ++i) a[i] = 0;
}

static void ss_copy(int64_t *dst, const int64_t *src, int n) {
    memmove(dst, src, (size_t)n * sizeof(int64_t));
}

static void ss_rot(int64_t *dst, const int64_t *src, int s, int d) {
    int f = d >= s;
    if (f) d -= s;
    int i = 0;
    if (f) {
        for (; i < s - d; ++i) dst[i + d] = -src[i];
        for (; i < s; ++i) dst[i + d - s] = src[i];
    } else {
        for (; i < s - d; ++i) dst[i + d] = src[i];
        for (; i < s; ++i) dst[i + d - s] = -src[i];
    }
}

static void ss_add(int64_t *dst, const int64_t *src, int n) {
    for (int i = 0; i < n; ++i) dst[i] += src[i];
}

static void ss_sub(int64_t *dst, const int64_t *src, int n) {
    for (int i = 0; i < n; ++i) dst[i] -= src[i];
}

static int ss_ctz(unsigned x) {
    int n = 0;
    while ((x & 1u) == 0u) { ++n; x >>= 1; }
    return n;
}

static void ss_fft(int64_t *a, int l, int m, int64_t *buf) {
    if (l == 0) return;
    int L = 1 << l, M = 1 << m;
    int dw[16];
    for (int i = 0; i < l - 1; ++i) {
        dw[i] = (1 << (l - 2 - i)) + (1 << (l - 1 - i)) - (1 << (l - 1));
        if (dw[i] < 0) dw[i] += L;
        if (L == M) dw[i] *= 2;
        if (2 * L == M) dw[i] *= 4;
    }
    for (int d = L; (d >>= 1) != 0;) {
        int w = 0;
        for (int s = 0, k = 0;;) {
            for (int i = s, j = s + d; i < s + d; ++i, ++j) {
                int64_t *ai = a + i * M, *aj = a + j * M;
                ss_rot(buf, aj, M, w);
                ss_copy(aj, ai, M);
                ss_add(ai, buf, M);
                ss_sub(aj, buf, M);
            }
            if ((s += 2 * d) >= L) break;
            w += dw[ss_ctz((unsigned)++k)];
            if (w >= 2 * M) w -= 2 * M;
        }
    }
}

static void ss_ifft(int64_t *a, int l, int m, int64_t *buf) {
    if (l == 0) return;
    int L = 1 << l, M = 1 << m;
    int dw[16];
    for (int i = 0; i < l - 1; ++i) {
        dw[i] = (1 << (l - 2 - i)) + (1 << (l - 1 - i)) - (1 << (l - 1));
        if (dw[i] < 0) dw[i] += L;
        if (L == M) dw[i] *= 2;
        if (2 * L == M) dw[i] *= 4;
    }
    for (int d = 1; d < L; d *= 2) {
        int w = 0;
        for (int s = 0, k = 0;;) {
            for (int i = s, j = s + d; i < s + d; ++i, ++j) {
                int64_t *ai = a + i * M, *aj = a + j * M;
                ss_copy(buf, ai, M);
                ss_add(ai, aj, M);
                ss_sub(buf, aj, M);
                ss_rot(aj, buf, M, w);
            }
            if ((s += 2 * d) >= L) break;
            w -= dw[ss_ctz((unsigned)++k)];
            if (w < 0) w += 2 * M;
        }
    }
}

static void ss_naive_mul(int64_t *a, const int64_t *b, int n, int64_t *buf) {
    int N = 1 << n;
    ss_reset(buf, N);
    for (int i = 0; i < N; ++i) {
        int j = 0;
        for (; j < N - i; ++j) buf[i + j] += a[i] * b[j];
        for (; j < N; ++j) buf[i + j - N] -= a[i] * b[j];
    }
    ss_copy(a, buf, N);
}

static void ss_inplace_mul(int64_t *a, const int64_t *b, int n, int64_t *buf) {
    if (n <= 5) { ss_naive_mul(a, b, n, buf); return; }
    int l = (n + 1) / 2, m = n / 2;
    int L = 1 << l, M = 1 << m, N = 1 << n;
    int64_t A[SS_SCRATCH] = {0}, B[SS_SCRATCH] = {0};
    ss_reset(buf + M, M);
    for (int i = 0, s = 0, ds = 2 * M / L; i < L; ++i) {
        ss_copy(buf, a + i * M, M);
        ss_rot(A + i * M * 2, buf, 2 * M, s);
        ss_copy(buf, b + i * M, M);
        ss_rot(B + i * M * 2, buf, 2 * M, s);
        s += ds; if (s >= 4 * M) s -= 4 * M;
    }
    ss_fft(A, l, m + 1, buf);
    ss_fft(B, l, m + 1, buf);
    for (int i = 0; i < L; ++i) ss_inplace_mul(A + i * M * 2, B + i * M * 2, m + 1, buf);
    ss_ifft(A, l, m + 1, buf);
    for (int i = 0, s = 0, ds = 2 * M / L; i < L; ++i) {
        ss_copy(buf, A + i * M * 2, 2 * M);
        ss_rot(A + i * M * 2, buf, 2 * M, s);
        s -= ds; if (s < 0) s += 4 * M;
    }
    for (int i = 0; i < L; ++i) for (int j = 0; j < M; ++j) {
        a[i * M + j] = A[i * M * 2 + j];
        if (i == 0) a[i * M + j] -= A[(L - 1) * M * 2 + M + j];
        else a[i * M + j] += A[(i - 1) * M * 2 + M + j];
    }
    (void)N;
}

static void ss_inplace_mul2(int64_t *a, const int64_t *b, int n, int64_t *buf) {
    if (n <= 5) { ss_naive_mul(a, b, n, buf); return; }
    int l = (n + 1) / 2, m = n / 2;
    int L = 1 << l, M = 1 << m, N = 1 << n;
    int64_t A[SS_SCRATCH] = {0}, B[SS_SCRATCH] = {0};
    for (int i = 0; i < L; ++i) {
        ss_copy(A + i * M * 2, a + i * M, M);
        ss_copy(B + i * M * 2, b + i * M, M);
    }
    ss_fft(A, l, m + 1, buf);
    ss_fft(B, l, m + 1, buf);
    for (int i = 0; i < L; ++i) ss_inplace_mul(A + i * M * 2, B + i * M * 2, m + 1, buf);
    ss_ifft(A, l, m + 1, buf);
    for (int i = 0; i < L; ++i) for (int j = 0; j < M; ++j) {
        a[i * M + j] = A[i * M * 2 + j] + A[(i ? i - 1 : L - 1) * M * 2 + M + j];
    }
    (void)N;
}

int64_t schoenhage_strassen_multiply(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (input == NULL || length != SS_INPUT_LENGTH || input[0] != SS_LIMBS) return -1;
    int64_t a[SS_PADDED] = {0}, b[SS_PADDED] = {0}, scratch[SS_PADDED] = {0};
    for (int i = 0; i < SS_LIMBS; ++i) {
        int64_t x = input[1 + i], y = input[1 + SS_LIMBS + i];
        if (x < 0 || x > 1 || y < 0 || y > 1) return -1;
        a[i] = x; b[i] = y;
    }
    if (a[SS_LIMBS - 1] != 1 || b[SS_LIMBS - 1] != 1) return -1;
    if (output == NULL || capacity < SS_OUTPUT_BYTES) return -2;
    ss_inplace_mul2(a, b, 11, scratch);
    int64_t carry = 0;
    uint8_t result[SS_OUTPUT_BYTES] = {0};
    for (int i = 0; i < 1025; ++i) {
        int64_t value = a[i] + carry;
        uint8_t bit = (uint8_t)(value % 2);
        carry = value / 2;
        if (bit) result[SS_OUTPUT_BYTES - 1 - (size_t)i / 8] |= (uint8_t)(1u << (i % 8));
    }
    int bit_index = 1025;
    while (carry > 0) {
        if (carry % 2) result[SS_OUTPUT_BYTES - 1 - (size_t)bit_index / 8] |= (uint8_t)(1u << (bit_index % 8));
        carry /= 2;
        ++bit_index;
    }
    memcpy(output, result, SS_OUTPUT_BYTES);
    return SS_OUTPUT_BYTES;
}
