// Uncompiled and unexecuted C3 half-GCD resultant draft.
module polynomial_resultant_half_gcd;
extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);
const long RP_MOD = 998244353;

struct RPPoly { usz n; long* v; }

fn RPPoly rp_new(usz n, bool* ok) {
    RPPoly p = {0, null};
    if (!*ok || n == 0) return p;
    p.v = (long*)calloc(n, sizeof(long));
    if (p.v == null) { *ok = false; return p; }
    p.n = n;
    return p;
}

fn void rp_free(RPPoly* p) { free(p.v); p.v = null; p.n = 0; }
fn void rp_trim(RPPoly* p) { while (p.n > 0 && p.v[p.n-1] == 0) p.n--; }

fn long rp_power(long x, usz n) {
    long answer = 1;
    while (n > 0) {
        if ((n & 1) != 0) answer = answer*x % RP_MOD;
        x = x*x % RP_MOD;
        n >>= 1;
    }
    return answer;
}

fn void rp_ntt(long* a, usz n, bool inverse) {
    usz j = 0;
    for (usz i = 1; i < n; i++) {
        usz bit = n >> 1;
        while ((j & bit) != 0) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) { long tmp = a[i]; a[i] = a[j]; a[j] = tmp; }
    }
    for (usz width = 2; width <= n; width *= 2) {
        long root = rp_power(3, (usz)(RP_MOD-1)/width);
        if (inverse) root = rp_power(root, (usz)(RP_MOD-2));
        for (usz start = 0; start < n; start += width) {
            long factor = 1;
            for (usz k = 0; k < width/2; k++) {
                long x = a[start+k], y = a[start+k+width/2]*factor % RP_MOD;
                a[start+k] = (x+y) % RP_MOD;
                a[start+k+width/2] = (x-y+RP_MOD) % RP_MOD;
                factor = factor*root % RP_MOD;
            }
        }
    }
    if (inverse) {
        long scale = rp_power((long)n, (usz)(RP_MOD-2));
        for (usz i = 0; i < n; i++) a[i] = a[i]*scale % RP_MOD;
    }
}

fn RPPoly rp_add(RPPoly a, RPPoly b, bool* ok) {
    RPPoly out = rp_new(a.n > b.n ? a.n : b.n, ok);
    if (!*ok) return out;
    for (usz i = 0; i < a.n; i++) out.v[i] = a.v[i];
    for (usz i = 0; i < b.n; i++) out.v[i] = (out.v[i]+b.v[i]) % RP_MOD;
    rp_trim(&out);
    return out;
}

fn RPPoly rp_mul(RPPoly a, RPPoly b, bool* ok) {
    if (!*ok || a.n == 0 || b.n == 0) return rp_new(0, ok);
    usz count = a.n+b.n-1;
    if (a.n <= 32 || b.n <= 32) {
        RPPoly out = rp_new(count, ok);
        if (!*ok) return out;
        for (usz i = 0; i < a.n; i++)
            for (usz j = 0; j < b.n; j++) out.v[i+j] = (out.v[i+j]+a.v[i]*b.v[j]) % RP_MOD;
        rp_trim(&out);
        return out;
    }
    usz size = 1;
    while (size < count) size *= 2;
    RPPoly left = rp_new(size, ok), right = rp_new(size, ok);
    if (!*ok) { rp_free(&left); rp_free(&right); return rp_new(0, ok); }
    for (usz i = 0; i < a.n; i++) left.v[i] = a.v[i];
    for (usz i = 0; i < b.n; i++) right.v[i] = b.v[i];
    rp_ntt(left.v, size, false); rp_ntt(right.v, size, false);
    for (usz i = 0; i < size; i++) left.v[i] = left.v[i]*right.v[i] % RP_MOD;
    rp_ntt(left.v, size, true);
    rp_free(&right);
    left.n = count;
    rp_trim(&left);
    return left;
}

fn RPPoly rp_inverse(RPPoly f, usz count, bool* ok) {
    RPPoly inverse = rp_new(1, ok);
    if (!*ok) return inverse;
    inverse.v[0] = rp_power(f.v[0], (usz)(RP_MOD-2));
    while (*ok && inverse.n < count) {
        usz size = 2*inverse.n;
        if (size > count) size = count;
        RPPoly prefix = {f.n < size ? f.n : size, f.v};
        RPPoly product = rp_mul(prefix, inverse, ok);
        RPPoly correction = rp_new(size, ok);
        if (*ok) {
            for (usz i = 0; i < size; i++) {
                long x = i < product.n ? product.v[i] : 0;
                correction.v[i] = (RP_MOD-x) % RP_MOD;
            }
            correction.v[0] = (correction.v[0]+2) % RP_MOD;
        }
        rp_free(&product);
        RPPoly updated = rp_mul(inverse, correction, ok);
        rp_free(&inverse); rp_free(&correction);
        inverse = rp_new(size, ok);
        if (*ok) for (usz i = 0; i < size && i < updated.n; i++) inverse.v[i] = updated.v[i];
        rp_free(&updated);
    }
    return inverse;
}

fn void rp_divrem(RPPoly a, RPPoly b, RPPoly* q, RPPoly* r, bool* ok) {
    *q = rp_new(0, ok); *r = rp_new(0, ok);
    if (!*ok) return;
    if (a.n < b.n) {
        *r = rp_new(a.n, ok);
        if (*ok) for (usz i = 0; i < a.n; i++) r.v[i] = a.v[i];
        return;
    }
    usz count = a.n-b.n+1;
    RPPoly high = rp_new(count, ok), reverse = rp_new(b.n, ok);
    if (*ok) {
        for (usz i = 0; i < count; i++) high.v[i] = a.v[a.n-1-i];
        for (usz i = 0; i < b.n; i++) reverse.v[i] = b.v[b.n-1-i];
    }
    RPPoly inv = *ok ? rp_inverse(reverse, count, ok) : rp_new(0, ok);
    RPPoly qr = rp_mul(high, inv, ok);
    rp_free(&high); rp_free(&reverse); rp_free(&inv);
    *q = rp_new(count, ok);
    if (*ok) for (usz i = 0; i < count; i++) {
        usz index = count-1-i;
        q.v[i] = index < qr.n ? qr.v[index] : 0;
    }
    rp_free(&qr);
    RPPoly removed = rp_mul(*q, b, ok);
    *r = rp_new(b.n-1, ok);
    if (*ok) for (usz i = 0; i < r.n; i++)
        r.v[i] = (a.v[i] - (i < removed.n ? removed.v[i] : 0) + RP_MOD) % RP_MOD;
    rp_free(&removed);
    rp_trim(q); rp_trim(r);
}

struct RPMatrix { RPPoly a; RPPoly b; RPPoly c; RPPoly d; }
struct RPHead { usz degree; long leading; }

fn void rp_matrix_free(RPMatrix* m) {
    rp_free(&m.a); rp_free(&m.b); rp_free(&m.c); rp_free(&m.d);
}
fn RPPoly rp_copy(RPPoly p, bool* ok) {
    RPPoly out = rp_new(p.n, ok);
    if (*ok) for (usz i = 0; i < p.n; i++) out.v[i] = p.v[i];
    return out;
}
// The returned high-part view borrows its input's allocation.
fn RPPoly rp_upper(RPPoly p, usz shift) {
    if (shift >= p.n) return {0, null};
    return {p.n-shift, p.v+shift};
}
fn RPMatrix rp_identity(bool* ok) {
    RPMatrix m = {};
    m.a = rp_new(1, ok); m.d = rp_new(1, ok);
    if (*ok) { m.a.v[0] = 1; m.d.v[0] = 1; }
    return m;
}
fn RPMatrix rp_step(RPPoly q, bool* ok) {
    RPMatrix m = {};
    m.b = rp_new(1, ok); m.c = rp_new(1, ok); m.d = rp_new(q.n, ok);
    if (*ok) {
        m.b.v[0] = 1; m.c.v[0] = 1;
        for (usz i = 0; i < q.n; i++) m.d.v[i] = (RP_MOD-q.v[i]) % RP_MOD;
    }
    return m;
}
fn RPPoly rp_dot(RPPoly a, RPPoly b, RPPoly c, RPPoly d, bool* ok) {
    RPPoly x = rp_mul(a, b, ok), y = rp_mul(c, d, ok);
    RPPoly result = rp_add(x, y, ok);
    rp_free(&x); rp_free(&y);
    return result;
}
fn RPMatrix rp_compose(RPMatrix x, RPMatrix y, bool* ok) {
    RPMatrix m = {};
    m.a = rp_dot(x.a, y.a, x.b, y.c, ok);
    m.b = rp_dot(x.a, y.b, x.b, y.d, ok);
    m.c = rp_dot(x.c, y.a, x.d, y.c, ok);
    m.d = rp_dot(x.c, y.b, x.d, y.d, ok);
    return m;
}
fn void rp_apply(RPMatrix m, RPPoly a, RPPoly b, RPPoly* x, RPPoly* y, bool* ok) {
    *x = rp_dot(m.a, a, m.b, b, ok);
    *y = rp_dot(m.c, a, m.d, b, ok);
}
fn RPMatrix rp_half(RPPoly a, RPPoly b, RPHead* heads, usz* count, bool* ok) {
    RPMatrix empty = {};
    if (!*ok) return empty;
    if (b.n == 0) return rp_identity(ok);
    usz degree = a.n-1, threshold = (degree+1)/2;
    if (b.n <= threshold) return rp_identity(ok);
    if (degree <= 64) {
        RPPoly x = rp_copy(a, ok), y = rp_copy(b, ok);
        RPMatrix matrix = rp_identity(ok);
        while (*ok && y.n > 0 && y.n > threshold) {
            RPPoly q, r;
            rp_divrem(x, y, &q, &r, ok);
            if (!*ok) { rp_free(&q); rp_free(&r); break; }
            heads[*count] = {q.n-1, q.v[q.n-1]}; *count += 1;
            RPMatrix step = rp_step(q, ok), next = rp_compose(step, matrix, ok);
            rp_matrix_free(&step); rp_matrix_free(&matrix); rp_free(&q); rp_free(&x);
            matrix = next; x = y; y = r;
        }
        rp_free(&x); rp_free(&y);
        return matrix;
    }
    RPMatrix first = rp_half(rp_upper(a, threshold), rp_upper(b, threshold), heads, count, ok);
    RPPoly c, d;
    rp_apply(first, a, b, &c, &d, ok);
    if (!*ok || d.n == 0 || d.n <= threshold) { rp_free(&c); rp_free(&d); return first; }
    RPPoly q, r;
    rp_divrem(c, d, &q, &r, ok);
    rp_free(&c);
    if (!*ok) { rp_free(&d); rp_free(&q); rp_free(&r); return first; }
    heads[*count] = {q.n-1, q.v[q.n-1]}; *count += 1;
    RPMatrix step = rp_step(q, ok), prefix = rp_compose(step, first, ok);
    rp_free(&q); rp_matrix_free(&step); rp_matrix_free(&first);
    if (!*ok || r.n == 0) { rp_free(&d); rp_free(&r); return prefix; }
    usz shift = 2*threshold-(d.n-1);
    if (shift >= r.n) { rp_free(&d); rp_free(&r); return prefix; }
    RPMatrix last = rp_half(rp_upper(d, shift), rp_upper(r, shift), heads, count, ok);
    RPMatrix result = rp_compose(last, prefix, ok);
    rp_matrix_free(&last); rp_matrix_free(&prefix); rp_free(&d); rp_free(&r);
    return result;
}

fn long rp_resultant(RPPoly* a, RPPoly* b, bool* ok) {
    long answer = 1;
    if (a.n < b.n) {
        if (((a.n-1)&1) != 0 && ((b.n-1)&1) != 0) answer = RP_MOD-answer;
        RPPoly tmp = *a; *a = *b; *b = tmp;
    }
    RPHead* heads = (RPHead*)calloc(a.n+1, sizeof(RPHead));
    if (heads == null) { *ok = false; return 0; }
    while (true) {
        if (b.n == 1) { answer = answer*rp_power(b.v[0], a.n-1) % RP_MOD; break; }
        usz count = 0;
        RPPoly c = {}, d = {};
        if (a.n != b.n) {
            RPMatrix matrix = rp_half(*a, *b, heads, &count, ok);
            if (*ok && count > 0) rp_apply(matrix, *a, *b, &c, &d, ok);
            rp_matrix_free(&matrix);
        }
        if (!*ok) { rp_free(&c); rp_free(&d); break; }
        if (count == 0) {
            RPPoly q, r;
            rp_divrem(*a, *b, &q, &r, ok);
            rp_free(&q);
            if (!*ok) { rp_free(&r); break; }
            if (r.n == 0) { rp_free(&r); answer = 0; break; }
            usz da = a.n-1, db = b.n-1, dr = r.n-1;
            if ((da&1) != 0 && (db&1) != 0) answer = RP_MOD-answer;
            answer = answer*rp_power(b.v[b.n-1], da-dr) % RP_MOD;
            rp_free(a); *a = *b; *b = r;
        } else {
            if (d.n == 0) { rp_free(&c); rp_free(&d); answer = 0; break; }
            usz da = a.n-1, db = b.n-1;
            long leading = b.v[b.n-1];
            for (usz i = 0; i < count; i++) {
                bool last = i+1 == count;
                usz dr = last ? d.n-1 : db-heads[i+1].degree;
                if ((da&1) != 0 && (db&1) != 0) answer = RP_MOD-answer;
                answer = answer*rp_power(leading, da-dr) % RP_MOD;
                if (!last) leading = leading*rp_power(heads[i+1].leading, (usz)(RP_MOD-2)) % RP_MOD;
                da = db; db = dr;
            }
            rp_free(a); rp_free(b); *a = c; *b = d;
        }
    }
    free(heads);
    return answer;
}

fn long polynomial_resultant_half_gcd(long* input, usz length) @export("polynomial_resultant_half_gcd") {
    if (input == null || length < 4 || length > 100002) return -1;
    long m = input[0], n = input[1];
    if (m < 0 || m > 50000 || n < 0 || n > 50000 || m+n > 99998) return -1;
    usz first_count = (usz)m+1, second_count = (usz)n+1;
    if (length != first_count+second_count+2) return -1;
    for (usz i = 2; i < length; i++) if (input[i] < 0 || input[i] >= RP_MOD) return -1;
    if (input[1+first_count] == 0 || input[length-1] == 0) return -1;
    bool ok = true;
    RPPoly a = rp_new(first_count, &ok), b = rp_new(second_count, &ok);
    if (ok) {
        for (usz i = 0; i < first_count; i++) a.v[i] = input[2+i];
        for (usz i = 0; i < second_count; i++) b.v[i] = input[2+first_count+i];
    }
    long result = ok ? rp_resultant(&a, &b, &ok) : -1;
    rp_free(&a); rp_free(&b);
    return ok ? result : -1;
}
