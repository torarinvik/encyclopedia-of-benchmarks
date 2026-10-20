module schoenhage_strassen_multiply;

const int LIMBS = 513;
const int PADDED = 2048;
const int SCRATCH = 4096;
const int OUTPUT_BYTES = 129;

fn void ss_zero(long* a, int n) { for (int i = 0; i < n; i++) a[i] = 0; }
fn void ss_copy(long* d, long* s, int n) { for (int i = 0; i < n; i++) d[i] = s[i]; }
fn void ss_add(long* d, long* s, int n) { for (int i = 0; i < n; i++) d[i] += s[i]; }
fn void ss_sub(long* d, long* s, int n) { for (int i = 0; i < n; i++) d[i] -= s[i]; }

fn void ss_rot(long* dst, long* src, int size, int shift) {
    bool f = shift >= size;
    if (f) shift -= size;
    int i = 0;
    if (f) {
        for (; i < size - shift; i++) dst[i + shift] = -src[i];
        for (; i < size; i++) dst[i + shift - size] = src[i];
    } else {
        for (; i < size - shift; i++) dst[i + shift] = src[i];
        for (; i < size; i++) dst[i + shift - size] = -src[i];
    }
}

fn int ss_ctz(uint value) {
    int bits = 0;
    while ((value & 1) == 0) { bits++; value >>= 1; }
    return bits;
}

fn void ss_fft(long* a, int l, int m, long* buf) {
    if (l == 0) return;
    int L = 1 << l, M = 1 << m;
    int[16] dw;
    for (int i = 0; i < l - 1; i++) {
        dw[i] = (1 << (l - 2 - i)) + (1 << (l - 1 - i)) - (1 << (l - 1));
        if (dw[i] < 0) dw[i] += L;
        if (L == M) dw[i] *= 2;
        if (2 * L == M) dw[i] *= 4;
    }
    for (int d = L / 2; d > 0; d /= 2) {
        int w = 0;
        for (int s = 0, k = 0;;) {
            for (int i = s, j = s + d; i < s + d; i++, j++) {
                long* ai = a + i * M; long* aj = a + j * M;
                ss_rot(buf, aj, M, w); ss_copy(aj, ai, M); ss_add(ai, buf, M); ss_sub(aj, buf, M);
            }
            s += 2 * d; if (s >= L) break;
            k++; w += dw[ss_ctz((uint)k)]; if (w >= 2 * M) w -= 2 * M;
        }
    }
}

fn void ss_ifft(long* a, int l, int m, long* buf) {
    if (l == 0) return;
    int L = 1 << l, M = 1 << m;
    int[16] dw;
    for (int i = 0; i < l - 1; i++) {
        dw[i] = (1 << (l - 2 - i)) + (1 << (l - 1 - i)) - (1 << (l - 1));
        if (dw[i] < 0) dw[i] += L;
        if (L == M) dw[i] *= 2;
        if (2 * L == M) dw[i] *= 4;
    }
    for (int d = 1; d < L; d *= 2) {
        int w = 0;
        for (int s = 0, k = 0;;) {
            for (int i = s, j = s + d; i < s + d; i++, j++) {
                long* ai = a + i * M; long* aj = a + j * M;
                ss_copy(buf, ai, M); ss_add(ai, aj, M); ss_sub(buf, aj, M); ss_rot(aj, buf, M, w);
            }
            s += 2 * d; if (s >= L) break;
            k++; w -= dw[ss_ctz((uint)k)]; if (w < 0) w += 2 * M;
        }
    }
}

fn void ss_naive(long* a, long* b, int n, long* buf) {
    int N = 1 << n; ss_zero(buf, N);
    for (int i = 0; i < N; i++) {
        int j = 0;
        for (; j < N - i; j++) buf[i + j] += a[i] * b[j];
        for (; j < N; j++) buf[i + j - N] -= a[i] * b[j];
    }
    ss_copy(a, buf, N);
}

fn void ss_mul(long* a, long* b, int n, long* buf) {
    if (n <= 5) { ss_naive(a, b, n, buf); return; }
    int l = (n + 1) / 2, m = n / 2, L = 1 << l, M = 1 << m;
    long[SCRATCH] A; long[SCRATCH] B;
    ss_zero(&A[0], SCRATCH); ss_zero(&B[0], SCRATCH); ss_zero(buf + M, M);
    for (int i = 0, s = 0, ds = 2 * M / L; i < L; i++) {
        ss_copy(buf, a + i * M, M); ss_rot(&A[i * M * 2], buf, 2 * M, s);
        ss_copy(buf, b + i * M, M); ss_rot(&B[i * M * 2], buf, 2 * M, s);
        s += ds; if (s >= 4 * M) s -= 4 * M;
    }
    ss_fft(&A[0], l, m + 1, buf); ss_fft(&B[0], l, m + 1, buf);
    for (int i = 0; i < L; i++) ss_mul(&A[i * M * 2], &B[i * M * 2], m + 1, buf);
    ss_ifft(&A[0], l, m + 1, buf);
    for (int i = 0, s = 0, ds = 2 * M / L; i < L; i++) {
        ss_copy(buf, &A[i * M * 2], 2 * M); ss_rot(&A[i * M * 2], buf, 2 * M, s);
        s -= ds; if (s < 0) s += 4 * M;
    }
    for (int i = 0; i < L; i++) for (int j = 0; j < M; j++) {
        a[i * M + j] = A[i * M * 2 + j];
        if (i == 0) a[i * M + j] -= A[(L - 1) * M * 2 + M + j];
        else a[i * M + j] += A[(i - 1) * M * 2 + M + j];
    }
}

fn void ss_mul_cyclic(long* a, long* b, int n, long* buf) {
    if (n <= 5) { ss_naive(a, b, n, buf); return; }
    int l = (n + 1) / 2, m = n / 2, L = 1 << l, M = 1 << m;
    long[SCRATCH] A; long[SCRATCH] B;
    ss_zero(&A[0], SCRATCH); ss_zero(&B[0], SCRATCH);
    for (int i = 0; i < L; i++) { ss_copy(&A[i * M * 2], a + i * M, M); ss_copy(&B[i * M * 2], b + i * M, M); }
    ss_fft(&A[0], l, m + 1, buf); ss_fft(&B[0], l, m + 1, buf);
    for (int i = 0; i < L; i++) ss_mul(&A[i * M * 2], &B[i * M * 2], m + 1, buf);
    ss_ifft(&A[0], l, m + 1, buf);
    for (int i = 0; i < L; i++) for (int j = 0; j < M; j++)
        a[i * M + j] = A[i * M * 2 + j] + A[(i == 0 ? L - 1 : i - 1) * M * 2 + M + j];
}

fn long schoenhage_strassen_multiply(long* input, usz length, uint8* output, usz capacity) @export("schoenhage_strassen_multiply") {
    if (input == null || length != 1027 || input[0] != LIMBS) return -1;
    long[PADDED] a; long[PADDED] b; long[PADDED] scratch;
    for (int i = 0; i < PADDED; i++) { a[i] = 0; b[i] = 0; scratch[i] = 0; }
    for (int i = 0; i < LIMBS; i++) {
        long x = input[1 + i], y = input[1 + LIMBS + i];
        if (x < 0 || x > 1 || y < 0 || y > 1) return -1;
        a[i] = x; b[i] = y;
    }
    if (a[LIMBS - 1] != 1 || b[LIMBS - 1] != 1) return -1;
    if (output == null || capacity < OUTPUT_BYTES) return -2;
    ss_mul_cyclic(&a[0], &b[0], 11, &scratch[0]);
    uint8[OUTPUT_BYTES] result; for (int i = 0; i < OUTPUT_BYTES; i++) result[i] = 0;
    long carry = 0;
    for (int i = 0; i < 1025; i++) {
        long value = a[i] + carry; uint8 bit = (uint8)(value % 2); carry = value / 2;
        if (bit != 0) result[OUTPUT_BYTES - 1 - i / 8] |= (uint8)(1 << (i % 8));
    }
    int bit_index = 1025;
    while (carry > 0) { if (carry % 2 != 0) result[OUTPUT_BYTES - 1 - bit_index / 8] |= (uint8)(1 << (bit_index % 8)); carry /= 2; bit_index++; }
    for (int i = 0; i < OUTPUT_BYTES; i++) output[i] = result[i];
    return OUTPUT_BYTES;
}
