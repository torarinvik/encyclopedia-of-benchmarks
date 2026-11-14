// Uncompiled bounded GF(2) quadratic normal-form draft.
module quadratic_form_gf2_normal_form;

struct QfVec { ulong lo; ulong hi; }
fn QfVec qf_xor(QfVec a, QfVec b) {
    QfVec value = {}; value.lo = a.lo ^ b.lo; value.hi = a.hi ^ b.hi; return value;
}
fn bool qf_bit(QfVec v, usz i) {
    return i < 64 ? ((v.lo >> i) & 1) != 0 : ((v.hi >> (i-64)) & 1) != 0;
}
fn void qf_set(QfVec* v, usz i) {
    if (i < 64) v.lo |= (ulong)1 << i; else v.hi |= (ulong)1 << (i-64);
}
fn int qf_parity(ulong x) {
    x ^= x >> 32; x ^= x >> 16; x ^= x >> 8;
    x ^= x >> 4; x ^= x >> 2; x ^= x >> 1;
    return (int)(x & 1);
}
fn int qf_apply(QfVec* rows, usz n, QfVec a, QfVec b) {
    int result = 0;
    for (usz i = 0; i < n; i++)
        if (qf_bit(a, i)) result ^= qf_parity((rows[i].lo & b.lo) ^ (rows[i].hi & b.hi));
    return result;
}

fn long quadratic_form_gf2_normal_form(long* input, usz length, char* output, usz capacity)
    @export("quadratic_form_gf2_normal_form") {
    if (input == null || length == 0 || length > 202 || input[0] < 1 || input[0] > 100) return -1;
    usz n = (usz)input[0], words = (n + 62) / 63;
    if (length != 1 + n*words) return -1;
    QfVec[100] upper; QfVec[100] polar; QfVec empty = {};
    for (usz i = 0; i < 100; i++) { upper[i] = empty; polar[i] = empty; }
    for (usz i = 0; i < n; i++) for (usz chunk = 0; chunk < words; chunk++) {
        long raw = input[1+i*words+chunk];
        if (raw < 0) return -1;
        for (usz b = 0; b < 63; b++) if ((((ulong)raw >> b) & 1) != 0) {
            usz j = 63*chunk+b;
            if (j >= n || j < i) return -1;
            qf_set(&upper[i], j);
            if (i != j) { qf_set(&polar[i], j); qf_set(&polar[j], i); }
        }
    }
    usz row_bytes = (n+7)/8, needed = 3+n*row_bytes;
    if (output == null || capacity < needed) return -2;
    QfVec[100] remaining; QfVec[100] hyper; QfVec[100] anis; QfVec[100] columns;
    for (usz i = 0; i < n; i++) { remaining[i] = empty; qf_set(&remaining[i], i); }
    usz count = n, hc = 0, ac = 0;
    while (true) {
        usz left = count, right = count;
        for (usz i = 0; i < count && left == count; i++) for (usz j = i+1; j < count; j++) {
            if (qf_apply(&polar[0], n, remaining[i], remaining[j]) != 0) { left = i; right = j; break; }
        }
        if (left == count) break;
        QfVec u = remaining[left], v = remaining[right];
        QfVec[100] rest; usz next = 0;
        for (usz i = 0; i < count; i++) {
            if (i == left || i == right) continue;
            QfVec w = remaining[i];
            if (qf_apply(&polar[0], n, remaining[i], v) != 0) w = qf_xor(w, u);
            if (qf_apply(&polar[0], n, remaining[i], u) != 0) w = qf_xor(w, v);
            rest[next++] = w;
        }
        count = next;
        for (usz i = 0; i < count; i++) remaining[i] = rest[i];
        int qu = qf_apply(&upper[0], n, u, u), qv = qf_apply(&upper[0], n, v, v);
        if (qu != 0 && qv != 0) { anis[ac++] = u; anis[ac++] = v; }
        else {
            if (qu != 0) u = qf_xor(u, v); else if (qv != 0) v = qf_xor(v, u);
            hyper[hc++] = u; hyper[hc++] = v;
        }
    }
    while (ac >= 4) {
        QfVec a = anis[ac-2], b = anis[ac-1], c = anis[ac-4], d = anis[ac-3];
        ac -= 4;
        QfVec f = qf_xor(d, qf_xor(a, b));
        hyper[hc++] = qf_xor(a, c); hyper[hc++] = qf_xor(b, c);
        hyper[hc++] = f; hyper[hc++] = qf_xor(f, c);
    }
    QfVec linear = {}; bool has_linear = false;
    for (usz i = 0; i < count; i++) if (qf_apply(&upper[0], n, remaining[i], remaining[i]) != 0) {
        linear = remaining[i]; has_linear = true;
        for (usz j = i+1; j < count; j++) remaining[j-1] = remaining[j];
        count--; break;
    }
    if (has_linear) {
        for (usz i = 0; i < count; i++)
            if (qf_apply(&upper[0], n, remaining[i], remaining[i]) != 0) remaining[i] = qf_xor(remaining[i], linear);
        if (ac != 0) {
            hyper[hc++] = qf_xor(anis[0], linear); hyper[hc++] = qf_xor(anis[1], linear); ac = 0;
        }
    }
    usz used = 0;
    for (usz i = 0; i < hc; i++) columns[used++] = hyper[i];
    for (usz i = 0; i < ac; i++) columns[used++] = anis[i];
    if (has_linear) columns[used++] = linear;
    for (usz i = 0; i < count; i++) columns[used++] = remaining[i];
    if (used != n || hc % 2 != 0 || (ac != 0 && ac != 2)) return -4;
    QfVec[100] matrix; QfVec[100] inverse;
    for (usz i = 0; i < n; i++) {
        matrix[i] = empty; inverse[i] = empty; qf_set(&inverse[i], i);
        for (usz j = 0; j < n; j++) if (qf_bit(columns[j], i)) qf_set(&matrix[i], j);
    }
    for (usz col = 0; col < n; col++) {
        usz pivot = col;
        while (pivot < n && !qf_bit(matrix[pivot], col)) pivot++;
        if (pivot == n) return -4;
        QfVec tmp = matrix[col]; matrix[col] = matrix[pivot]; matrix[pivot] = tmp;
        tmp = inverse[col]; inverse[col] = inverse[pivot]; inverse[pivot] = tmp;
        for (usz row = 0; row < n; row++) if (row != col && qf_bit(matrix[row], col)) {
            matrix[row] = qf_xor(matrix[row], matrix[col]); inverse[row] = qf_xor(inverse[row], inverse[col]);
        }
    }
    char[1303] staged;
    for (usz i = 0; i < needed; i++) staged[i] = 0;
    staged[0] = (char)(hc/2); staged[1] = (char)(ac/2); staged[2] = has_linear ? 1 : 0;
    for (usz i = 0; i < n; i++) for (usz j = 0; j < n; j++)
        if (qf_bit(inverse[i], j)) staged[3+i*row_bytes+j/8] |= (char)(1 << (j%8));
    for (usz i = 0; i < needed; i++) output[i] = staged[i];
    return (long)needed;
}
