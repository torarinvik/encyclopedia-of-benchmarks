/* Uncompiled and unexecuted C half-GCD resultant draft. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define RP_MOD INT64_C(998244353)

typedef struct { size_t n; int64_t *v; } rp_poly;

static rp_poly rp_new(size_t n, int *ok) {
    rp_poly p = {0, NULL};
    if (!*ok || n == 0) return p;
    p.v = calloc(n, sizeof(*p.v));
    if (!p.v) { *ok = 0; return p; }
    p.n = n;
    return p;
}

static void rp_free(rp_poly *p) { free(p->v); p->v = NULL; p->n = 0; }
static void rp_trim(rp_poly *p) { while (p->n && p->v[p->n - 1] == 0) --p->n; }

static int64_t rp_power(int64_t base, size_t exponent) {
    int64_t answer = 1;
    while (exponent) {
        if (exponent & 1) answer = answer * base % RP_MOD;
        base = base * base % RP_MOD;
        exponent >>= 1;
    }
    return answer;
}

static void rp_ntt(int64_t *a, size_t n, int inverse) {
    for (size_t i = 1, j = 0; i < n; ++i) {
        size_t bit = n >> 1;
        for (; j & bit; bit >>= 1) j ^= bit;
        j ^= bit;
        if (i < j) { int64_t t = a[i]; a[i] = a[j]; a[j] = t; }
    }
    for (size_t width = 2; width <= n; width <<= 1) {
        int64_t root = rp_power(3, (size_t)(RP_MOD - 1) / width);
        if (inverse) root = rp_power(root, RP_MOD - 2);
        for (size_t start = 0; start < n; start += width) {
            int64_t factor = 1;
            for (size_t k = 0; k < width / 2; ++k) {
                int64_t x = a[start+k], y = a[start+k+width/2] * factor % RP_MOD;
                a[start+k] = (x+y) % RP_MOD;
                a[start+k+width/2] = (x-y+RP_MOD) % RP_MOD;
                factor = factor * root % RP_MOD;
            }
        }
    }
    if (inverse) {
        int64_t scale = rp_power((int64_t)n, RP_MOD - 2);
        for (size_t i = 0; i < n; ++i) a[i] = a[i] * scale % RP_MOD;
    }
}

static rp_poly rp_add(const rp_poly *a, const rp_poly *b, int *ok) {
    rp_poly out = rp_new(a->n > b->n ? a->n : b->n, ok);
    if (!*ok) return out;
    for (size_t i = 0; i < a->n; ++i) out.v[i] = a->v[i];
    for (size_t i = 0; i < b->n; ++i) out.v[i] = (out.v[i] + b->v[i]) % RP_MOD;
    rp_trim(&out);
    return out;
}

static rp_poly rp_mul(const rp_poly *a, const rp_poly *b, int *ok) {
    if (!*ok || !a->n || !b->n) return rp_new(0, ok);
    size_t count = a->n + b->n - 1;
    if (a->n <= 32 || b->n <= 32) {
        rp_poly out = rp_new(count, ok);
        if (!*ok) return out;
        for (size_t i = 0; i < a->n; ++i)
            for (size_t j = 0; j < b->n; ++j)
                out.v[i+j] = (out.v[i+j] + a->v[i]*b->v[j]) % RP_MOD;
        rp_trim(&out);
        return out;
    }
    size_t size = 1;
    while (size < count) size <<= 1;
    rp_poly left = rp_new(size, ok), right = rp_new(size, ok);
    if (!*ok) { rp_free(&left); rp_free(&right); return rp_new(0, ok); }
    for (size_t i = 0; i < a->n; ++i) left.v[i] = a->v[i];
    for (size_t i = 0; i < b->n; ++i) right.v[i] = b->v[i];
    rp_ntt(left.v, size, 0); rp_ntt(right.v, size, 0);
    for (size_t i = 0; i < size; ++i) left.v[i] = left.v[i]*right.v[i] % RP_MOD;
    rp_ntt(left.v, size, 1);
    rp_free(&right);
    left.n = count;
    rp_trim(&left);
    return left;
}

/* Result preserves exactly count coefficients, including trailing zeroes. */
static rp_poly rp_inverse(const rp_poly *f, size_t count, int *ok) {
    rp_poly inverse = rp_new(1, ok);
    if (!*ok) return inverse;
    inverse.v[0] = rp_power(f->v[0], RP_MOD - 2);
    while (*ok && inverse.n < count) {
        size_t size = 2*inverse.n;
        if (size > count) size = count;
        rp_poly prefix = {f->n < size ? f->n : size, f->v};
        rp_poly product = rp_mul(&prefix, &inverse, ok);
        rp_poly correction = rp_new(size, ok);
        if (*ok) {
            for (size_t i = 0; i < size; ++i) {
                int64_t value = i < product.n ? product.v[i] : 0;
                correction.v[i] = (RP_MOD - value) % RP_MOD;
            }
            correction.v[0] = (correction.v[0] + 2) % RP_MOD;
        }
        rp_free(&product);
        rp_poly updated = rp_mul(&inverse, &correction, ok);
        rp_free(&correction); rp_free(&inverse);
        inverse = rp_new(size, ok);
        if (*ok) for (size_t i = 0; i < size && i < updated.n; ++i) inverse.v[i] = updated.v[i];
        rp_free(&updated);
    }
    return inverse;
}

/* The caller owns both returned polynomials; divisor must be nonzero. */
static void rp_divrem(const rp_poly *a, const rp_poly *b, rp_poly *q, rp_poly *r, int *ok) {
    *q = rp_new(0, ok); *r = rp_new(0, ok);
    if (!*ok) return;
    if (a->n < b->n) {
        *r = rp_new(a->n, ok);
        if (*ok) for (size_t i = 0; i < a->n; ++i) r->v[i] = a->v[i];
        return;
    }
    size_t count = a->n - b->n + 1;
    rp_poly high = rp_new(count, ok), reverse = rp_new(b->n, ok);
    if (*ok) {
        for (size_t i = 0; i < count; ++i) high.v[i] = a->v[a->n - 1 - i];
        for (size_t i = 0; i < b->n; ++i) reverse.v[i] = b->v[b->n - 1 - i];
    }
    rp_poly inv = *ok ? rp_inverse(&reverse, count, ok) : rp_new(0, ok);
    rp_poly qrev = rp_mul(&high, &inv, ok);
    rp_free(&high); rp_free(&reverse); rp_free(&inv);
    *q = rp_new(count, ok);
    if (*ok) for (size_t i = 0; i < count; ++i) {
        size_t index = count - 1 - i;
        q->v[i] = index < qrev.n ? qrev.v[index] : 0;
    }
    rp_free(&qrev);
    rp_poly removed = rp_mul(q, b, ok);
    *r = rp_new(b->n - 1, ok);
    if (*ok) for (size_t i = 0; i < r->n; ++i)
        r->v[i] = (a->v[i] - (i < removed.n ? removed.v[i] : 0) + RP_MOD) % RP_MOD;
    rp_free(&removed);
    rp_trim(q); rp_trim(r);
}

typedef struct { rp_poly a, b, c, d; } rp_matrix;
typedef struct { size_t degree; int64_t leading; } rp_head;

static void rp_matrix_free(rp_matrix *m) {
    rp_free(&m->a); rp_free(&m->b); rp_free(&m->c); rp_free(&m->d);
}

static rp_poly rp_copy(const rp_poly *p, int *ok) {
    rp_poly out = rp_new(p->n, ok);
    if (*ok) for (size_t i = 0; i < p->n; ++i) out.v[i] = p->v[i];
    return out;
}

/* Views borrow storage and must not be passed to rp_free. */
static rp_poly rp_upper(const rp_poly *p, size_t shift) {
    if (shift >= p->n) return (rp_poly){0, NULL};
    return (rp_poly){p->n - shift, p->v + shift};
}

static rp_matrix rp_identity(int *ok) {
    rp_matrix m = {0};
    m.a = rp_new(1, ok); m.d = rp_new(1, ok);
    if (*ok) { m.a.v[0] = 1; m.d.v[0] = 1; }
    return m;
}

static rp_matrix rp_step(const rp_poly *q, int *ok) {
    rp_matrix m = {0};
    m.b = rp_new(1, ok); m.c = rp_new(1, ok); m.d = rp_new(q->n, ok);
    if (*ok) {
        m.b.v[0] = 1; m.c.v[0] = 1;
        for (size_t i = 0; i < q->n; ++i) m.d.v[i] = (RP_MOD-q->v[i]) % RP_MOD;
    }
    return m;
}

static rp_poly rp_dot(const rp_poly *a, const rp_poly *b,
                      const rp_poly *c, const rp_poly *d, int *ok) {
    rp_poly x = rp_mul(a, b, ok), y = rp_mul(c, d, ok);
    rp_poly result = rp_add(&x, &y, ok);
    rp_free(&x); rp_free(&y);
    return result;
}

static rp_matrix rp_compose(const rp_matrix *x, const rp_matrix *y, int *ok) {
    rp_matrix m = {0};
    m.a = rp_dot(&x->a, &y->a, &x->b, &y->c, ok);
    m.b = rp_dot(&x->a, &y->b, &x->b, &y->d, ok);
    m.c = rp_dot(&x->c, &y->a, &x->d, &y->c, ok);
    m.d = rp_dot(&x->c, &y->b, &x->d, &y->d, ok);
    return m;
}

static void rp_apply(const rp_matrix *m, const rp_poly *a, const rp_poly *b,
                     rp_poly *x, rp_poly *y, int *ok) {
    *x = rp_dot(&m->a, a, &m->b, b, ok);
    *y = rp_dot(&m->c, a, &m->d, b, ok);
}

/* Heads have room for the original degree plus one entries. */
static rp_matrix rp_half(const rp_poly *a, const rp_poly *b,
                         rp_head *heads, size_t *count, int *ok) {
    rp_matrix empty = {0};
    if (!*ok) return empty;
    if (!b->n) return rp_identity(ok);
    size_t degree = a->n - 1, threshold = (degree + 1) / 2;
    if (b->n <= threshold) return rp_identity(ok);
    if (degree <= 64) {
        rp_poly x = rp_copy(a, ok), y = rp_copy(b, ok);
        rp_matrix matrix = rp_identity(ok);
        while (*ok && y.n && y.n > threshold) {
            rp_poly q, r;
            rp_divrem(&x, &y, &q, &r, ok);
            if (!*ok) { rp_free(&q); rp_free(&r); break; }
            heads[*count] = (rp_head){q.n-1, q.v[q.n-1]}; ++*count;
            rp_matrix step = rp_step(&q, ok), next = rp_compose(&step, &matrix, ok);
            rp_matrix_free(&step); rp_matrix_free(&matrix); rp_free(&q); rp_free(&x);
            matrix = next; x = y; y = r;
        }
        rp_free(&x); rp_free(&y);
        return matrix;
    }
    rp_poly high_a = rp_upper(a, threshold), high_b = rp_upper(b, threshold);
    rp_matrix first = rp_half(&high_a, &high_b, heads, count, ok);
    rp_poly c, d;
    rp_apply(&first, a, b, &c, &d, ok);
    if (!*ok || !d.n || d.n <= threshold) { rp_free(&c); rp_free(&d); return first; }
    rp_poly q, r;
    rp_divrem(&c, &d, &q, &r, ok);
    rp_free(&c);
    if (!*ok) { rp_free(&d); rp_free(&q); rp_free(&r); return first; }
    heads[*count] = (rp_head){q.n-1, q.v[q.n-1]}; ++*count;
    rp_matrix step = rp_step(&q, ok), prefix = rp_compose(&step, &first, ok);
    rp_free(&q); rp_matrix_free(&step); rp_matrix_free(&first);
    if (!*ok || !r.n) { rp_free(&d); rp_free(&r); return prefix; }
    size_t shift = 2*threshold - (d.n-1);
    if (shift >= r.n) { rp_free(&d); rp_free(&r); return prefix; }
    rp_poly upper_d = rp_upper(&d, shift), upper_r = rp_upper(&r, shift);
    rp_matrix last = rp_half(&upper_d, &upper_r, heads, count, ok);
    rp_matrix result = rp_compose(&last, &prefix, ok);
    rp_matrix_free(&last); rp_matrix_free(&prefix); rp_free(&d); rp_free(&r);
    return result;
}

/* Owns and updates a and b; caller frees both after return. */
static int64_t rp_resultant(rp_poly *a, rp_poly *b, int *ok) {
    int64_t answer = 1;
    if (a->n < b->n) {
        if (((a->n-1)&1) && ((b->n-1)&1)) answer = RP_MOD-answer;
        rp_poly temp = *a; *a = *b; *b = temp;
    }
    rp_head *heads = calloc(a->n + 1, sizeof(*heads));
    if (!heads) { *ok = 0; return 0; }
    for (;;) {
        if (b->n == 1) { answer = answer*rp_power(b->v[0], a->n-1)%RP_MOD; break; }
        size_t count = 0;
        rp_poly c = {0}, d = {0};
        if (a->n != b->n) {
            rp_matrix matrix = rp_half(a, b, heads, &count, ok);
            if (*ok && count) rp_apply(&matrix, a, b, &c, &d, ok);
            rp_matrix_free(&matrix);
        }
        if (!*ok) { rp_free(&c); rp_free(&d); break; }
        if (!count) {
            rp_poly q, r;
            rp_divrem(a, b, &q, &r, ok);
            rp_free(&q);
            if (!*ok) { rp_free(&r); break; }
            if (!r.n) { rp_free(&r); answer = 0; break; }
            size_t da = a->n-1, db = b->n-1, dr = r.n-1;
            if ((da&1) && (db&1)) answer = RP_MOD-answer;
            answer = answer*rp_power(b->v[b->n-1], da-dr)%RP_MOD;
            rp_free(a); *a = *b; *b = r;
        } else {
            if (!d.n) { rp_free(&c); rp_free(&d); answer = 0; break; }
            size_t da = a->n-1, db = b->n-1;
            int64_t leading = b->v[b->n-1];
            for (size_t i = 0; i < count; ++i) {
                int last = i+1 == count;
                size_t dr = last ? d.n-1 : db-heads[i+1].degree;
                if ((da&1) && (db&1)) answer = RP_MOD-answer;
                answer = answer*rp_power(leading, da-dr)%RP_MOD;
                if (!last) leading = leading*rp_power(heads[i+1].leading, RP_MOD-2)%RP_MOD;
                da = db; db = dr;
            }
            rp_free(a); rp_free(b); *a = c; *b = d;
        }
    }
    free(heads);
    return answer;
}

int64_t polynomial_resultant_half_gcd(const int64_t *input, size_t length) {
    if (!input || length < 4 || length > 100002) return -1;
    int64_t m = input[0], n = input[1];
    if (m < 0 || m > 50000 || n < 0 || n > 50000 || m+n > 99998) return -1;
    size_t first_count = (size_t)m+1, second_count = (size_t)n+1;
    if (length != first_count+second_count+2) return -1;
    for (size_t i = 2; i < length; ++i)
        if (input[i] < 0 || input[i] >= RP_MOD) return -1;
    if (input[1+first_count] == 0 || input[length-1] == 0) return -1;
    int ok = 1;
    rp_poly a = rp_new(first_count, &ok), b = rp_new(second_count, &ok);
    if (ok) {
        for (size_t i = 0; i < first_count; ++i) a.v[i] = input[2+i];
        for (size_t i = 0; i < second_count; ++i) b.v[i] = input[2+first_count+i];
    }
    int64_t result = ok ? rp_resultant(&a, &b, &ok) : -1;
    rp_free(&a); rp_free(&b);
    return ok ? result : -1;
}
