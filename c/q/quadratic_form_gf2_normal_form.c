/* Uncompiled GF(2) quadratic normal-form draft. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

typedef struct { uint64_t w[2]; } qf_vector;

static qf_vector qf_xor(qf_vector a, qf_vector b) {
    return (qf_vector){{a.w[0] ^ b.w[0], a.w[1] ^ b.w[1]}};
}
static unsigned qf_bit(qf_vector v, size_t i) {
    return (unsigned)((v.w[i / 64] >> (i % 64)) & 1u);
}
static void qf_set(qf_vector *v, size_t i) {
    v->w[i / 64] |= UINT64_C(1) << (i % 64);
}
static unsigned qf_parity(uint64_t v) {
    v ^= v >> 32; v ^= v >> 16; v ^= v >> 8;
    v ^= v >> 4; v ^= v >> 2; v ^= v >> 1;
    return (unsigned)(v & 1u);
}
static unsigned qf_dot(qf_vector a, qf_vector b) {
    return qf_parity((a.w[0] & b.w[0]) ^ (a.w[1] & b.w[1]));
}
static unsigned qf_value(const qf_vector upper[100], size_t n, qf_vector x) {
    unsigned value = 0;
    for (size_t i = 0; i < n; ++i)
        if (qf_bit(x, i)) value ^= qf_dot(upper[i], x);
    return value;
}
static unsigned qf_polar(const qf_vector polar[100], size_t n, qf_vector a, qf_vector b) {
    unsigned value = 0;
    for (size_t i = 0; i < n; ++i)
        if (qf_bit(a, i)) value ^= qf_dot(polar[i], b);
    return value;
}

/* Input: n, followed by n rows of ceil(n/63) little-endian 63-bit words.
   Output: one byte each for r,s,t, then n rows of ceil(n/8) little-endian
   bits for P in y=P*x. No output is modified on any error. */
int64_t quadratic_form_gf2_normal_form(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (!input || length < 1 || length > 202 || input[0] < 1 || input[0] > 100) return -1;
    size_t n = (size_t)input[0], words = (n + 62) / 63;
    if (length != 1 + n * words) return -1;
    qf_vector upper[100] = {{{0}}}, polar[100] = {{{0}}};
    for (size_t i = 0; i < n; ++i) {
        for (size_t chunk = 0; chunk < words; ++chunk) {
            int64_t raw = input[1 + i * words + chunk];
            if (raw < 0) return -1;
            for (size_t bit = 0; bit < 63; ++bit) {
                size_t j = 63 * chunk + bit;
                if (((uint64_t)raw >> bit) & 1u) {
                    if (j >= n || j < i) return -1;
                    qf_set(&upper[i], j);
                    if (i != j) { qf_set(&polar[i], j); qf_set(&polar[j], i); }
                }
            }
        }
    }
    size_t row_bytes = (n + 7) / 8, needed = 3 + n * row_bytes;
    if (!output || capacity < needed) return -2;

    qf_vector remaining[100], rest[100], hyper[100], anis[100], columns[100];
    size_t count = n, hc = 0, ac = 0;
    for (size_t i = 0; i < n; ++i) { remaining[i] = (qf_vector){{0, 0}}; qf_set(&remaining[i], i); }
    for (;;) {
        size_t left = count, right = count;
        for (size_t i = 0; i < count && left == count; ++i)
            for (size_t j = i + 1; j < count; ++j)
                if (qf_polar(polar, n, remaining[i], remaining[j])) { left = i; right = j; break; }
        if (left == count) break;
        qf_vector u = remaining[left], v = remaining[right];
        size_t used = 0;
        for (size_t i = 0; i < count; ++i) if (i != left && i != right) {
            qf_vector w = remaining[i];
            if (qf_polar(polar, n, remaining[i], v)) w = qf_xor(w, u);
            if (qf_polar(polar, n, remaining[i], u)) w = qf_xor(w, v);
            rest[used++] = w;
        }
        memcpy(remaining, rest, used * sizeof(*rest)); count = used;
        unsigned qu = qf_value(upper, n, u), qv = qf_value(upper, n, v);
        if (qu && qv) { anis[ac++] = u; anis[ac++] = v; }
        else {
            if (qu) u = qf_xor(u, v); else if (qv) v = qf_xor(v, u);
            hyper[hc++] = u; hyper[hc++] = v;
        }
    }
    while (ac >= 4) {
        qf_vector b = anis[--ac], a = anis[--ac];
        qf_vector d = anis[--ac], c = anis[--ac];
        hyper[hc++] = qf_xor(a, c); hyper[hc++] = qf_xor(b, c);
        qf_vector f = qf_xor(d, qf_xor(a, b));
        hyper[hc++] = f; hyper[hc++] = qf_xor(f, c);
    }
    qf_vector linear = {{0, 0}};
    int has_linear = 0;
    for (size_t i = 0; i < count; ++i) if (qf_value(upper, n, remaining[i])) {
        linear = remaining[i]; has_linear = 1;
        for (size_t j = i + 1; j < count; ++j) remaining[j - 1] = remaining[j];
        --count; break;
    }
    if (has_linear) {
        for (size_t i = 0; i < count; ++i)
            if (qf_value(upper, n, remaining[i])) remaining[i] = qf_xor(remaining[i], linear);
        if (ac) {
            hyper[hc++] = qf_xor(anis[0], linear);
            hyper[hc++] = qf_xor(anis[1], linear);
            ac = 0;
        }
    }
    size_t used = 0;
    for (size_t i = 0; i < hc; ++i) columns[used++] = hyper[i];
    for (size_t i = 0; i < ac; ++i) columns[used++] = anis[i];
    if (has_linear) columns[used++] = linear;
    for (size_t i = 0; i < count; ++i) columns[used++] = remaining[i];
    if (used != n || (hc & 1u) || (ac != 0 && ac != 2)) return -4;

    qf_vector matrix[100] = {{{0}}}, inverse[100] = {{{0}}};
    for (size_t i = 0; i < n; ++i) {
        qf_set(&inverse[i], i);
        for (size_t j = 0; j < n; ++j) if (qf_bit(columns[j], i)) qf_set(&matrix[i], j);
    }
    for (size_t col = 0; col < n; ++col) {
        size_t pivot = col;
        while (pivot < n && !qf_bit(matrix[pivot], col)) ++pivot;
        if (pivot == n) return -4;
        qf_vector tmp = matrix[col]; matrix[col] = matrix[pivot]; matrix[pivot] = tmp;
        tmp = inverse[col]; inverse[col] = inverse[pivot]; inverse[pivot] = tmp;
        for (size_t row = 0; row < n; ++row) if (row != col && qf_bit(matrix[row], col)) {
            matrix[row] = qf_xor(matrix[row], matrix[col]);
            inverse[row] = qf_xor(inverse[row], inverse[col]);
        }
    }
    uint8_t staged[1303] = {0};
    staged[0] = (uint8_t)(hc / 2); staged[1] = (uint8_t)(ac / 2); staged[2] = (uint8_t)has_linear;
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < n; ++j)
            if (qf_bit(inverse[i], j)) staged[3 + i * row_bytes + j / 8] |= (uint8_t)(1u << (j % 8));
    memcpy(output, staged, needed);
    return (int64_t)needed;
}
