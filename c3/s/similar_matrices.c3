module similar_matrices;

const usz SM_MAX_VALUES = 19;

fn long sm_det3(long* m) {
    return m[0] * (m[4] * m[8] - m[5] * m[7])
         - m[1] * (m[3] * m[8] - m[5] * m[6])
         + m[2] * (m[3] * m[7] - m[4] * m[6]);
}

fn void sm_charpoly(long* m, usz n, long* out) {
    long trace = 0;
    for (usz i = 0; i < n; i++) trace += m[i * n + i];
    out[0] = -trace; out[1] = 0; out[2] = 0;
    if (n == 2) out[1] = m[0] * m[3] - m[1] * m[2];
    if (n == 3) {
        out[1] = (m[0] * m[4] - m[1] * m[3])
               + (m[0] * m[8] - m[2] * m[6])
               + (m[4] * m[8] - m[5] * m[7]);
        out[2] = -sm_det3(m);
    }
}

fn long sm_disc3(long a, long b, long c) {
    return a*a*b*b - 4*b*b*b - 4*a*a*a*c - 27*c*c + 18*a*b*c;
}

fn usz sm_rank_singular(long* m, usz n) {
    for (usz r0 = 0; r0 < n; r0++) {
        for (usz r1 = r0 + 1; r1 < n; r1++) {
            for (usz c0 = 0; c0 < n; c0++) {
                for (usz c1 = c0 + 1; c1 < n; c1++) {
                    if (m[r0*n+c0] * m[r1*n+c1] - m[r0*n+c1] * m[r1*n+c0] != 0) return 2;
                }
            }
        }
    }
    for (usz i = 0; i < n*n; i++) if (m[i] != 0) return 1;
    return 0;
}

fn void sm_shifted(long* m, usz n, long numerator, long denominator, long* out) {
    for (usz i = 0; i < n*n; i++) out[i] = denominator * m[i];
    for (usz i = 0; i < n; i++) out[i*n+i] -= numerator;
}

fn void sm_multiply(long* a, long* b, usz n, long* out) {
    for (usz row = 0; row < n; row++) {
        for (usz col = 0; col < n; col++) {
            long value = 0;
            for (usz k = 0; k < n; k++) value += a[row*n+k] * b[k*n+col];
            out[row*n+col] = value;
        }
    }
}

fn bool sm_similar(long* a, long* b, usz n) {
    long ca[3]; long cb[3];
    sm_charpoly(a,n,ca); sm_charpoly(b,n,cb);
    if (ca[0] != cb[0] || ca[1] != cb[1] || ca[2] != cb[2]) return false;
    if (n == 1) return true;
    if (n == 2) {
        if (ca[0]*ca[0] - 4*ca[1] != 0) return true;
        long da[9]; long db[9];
        sm_shifted(a,n,-ca[0],2,da); sm_shifted(b,n,-ca[0],2,db);
        return sm_rank_singular(da,n) == sm_rank_singular(db,n);
    }
    if (sm_disc3(ca[0],ca[1],ca[2]) != 0) return true;
    long q = ca[0]*ca[0] - 3*ca[1];
    long da[9]; long db[9];
    if (q == 0) {
        sm_shifted(a,n,-ca[0],3,da); sm_shifted(b,n,-ca[0],3,db);
        if (sm_rank_singular(da,n) != sm_rank_singular(db,n)) return false;
        long da2[9]; long db2[9];
        sm_multiply(da,da,n,da2); sm_multiply(db,db,n,db2);
        return sm_rank_singular(da2,n) == sm_rank_singular(db2,n);
    }
    long numerator = 9*ca[2] - ca[0]*ca[1];
    long denominator = 2*q;
    sm_shifted(a,n,numerator,denominator,da); sm_shifted(b,n,numerator,denominator,db);
    return sm_rank_singular(da,n) == sm_rank_singular(db,n);
}

fn long similar_matrices(long* input, usz length) @export("similar_matrices") {
    if (input == null || length < 1 || length > SM_MAX_VALUES) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > 3) return -1;
    usz n = (usz)n_value;
    usz matrix_size = n*n;
    if (length != 1 + 2*matrix_size) return -1;
    long a[9]; long b[9];
    for (usz i = 0; i < 2*matrix_size; i++) {
        long value = input[1+i];
        if (value < -5 || value > 5) return -1;
        if (i < matrix_size) a[i] = value;
        else b[i-matrix_size] = value;
    }
    return sm_similar(a,b,n) ? 1 : 0;
}
