module parboil_spmv_jds;

fn float decode(long v) { return v.float() / 1000000.0f; }
fn void put32(uchar* o, usz p, uint x) {
    o[p] = (uchar)x; o[p+1] = (uchar)(x >> 8); o[p+2] = (uchar)(x >> 16); o[p+3] = (uchar)(x >> 24);
}

fn long parboil_spmv_jds(long* in, usz len, uchar* out, usz cap) @export("parboil_spmv_jds") {
    if (in == null || len < 3 || len > 164) return -1;
    if (in[0] < 1 || in[0] > 8 || in[1] < 1 || in[1] > 8 || in[2] < 1 || in[2] > 64) return -1;
    usz n = in[0].usz(), d = in[1].usz(), z = in[2].usz();
    if (len != 4 + 3*n + d + 2*z) return -1;
    long[8] row = zeroed, perm = zeroed, vec = zeroed;
    long[9] ptr = zeroed;
    long[64] col = zeroed, data = zeroed;
    usz p = 3;
    for (usz i=0; i<n; i++) { if (in[p] < 0 || in[p] > d.long()) return -1; row[i] = in[p]; p++; }
    if (row[0] != d.long()) return -1;
    for (usz i=1; i<n; i++) if (row[i] > row[i-1]) return -1;
    for (usz i=0; i<n; i++) { perm[i] = in[p]; p++; }
    for (usz i=0; i<n; i++) {
        if (perm[i] < 0 || perm[i] >= n.long()) return -1;
        for (usz j=0; j<i; j++) if (perm[j] == perm[i]) return -1;
    }
    for (usz k=0; k<=d; k++) { ptr[k] = in[p]; p++; }
    for (usz j=0; j<z; j++) { col[j] = in[p]; p++; }
    for (usz j=0; j<z; j++) { data[j] = in[p]; p++; }
    for (usz i=0; i<n; i++) { vec[i] = in[p]; p++; }
    if (ptr[0] != 0) return -1;
    usz off = 0;
    for (usz k=0; k<d; k++) {
        usz count = 0;
        for (usz i=0; i<n; i++) if (row[i] > k.long()) count++;
        off += count;
        if (ptr[k+1] != off.long()) return -1;
    }
    if (off != z) return -1;
    for (usz j=0; j<z; j++) if (col[j] < 0 || col[j] >= n.long() || data[j] < -1000000 || data[j] > 1000000) return -1;
    for (usz i=0; i<n; i++) if (vec[i] < -1000000 || vec[i] > 1000000) return -1;
    if (out == null || cap < 4 + 4*n) return -2;
    float[8] y = zeroed; uchar[36] staged = zeroed;
    for (usz i=0; i<n; i++) {
        float acc = 0.0f;
        for (usz k=0; k<row[i].usz(); k++) {
            usz j = ptr[k].usz() + i;
            float product = decode(data[j]) * decode(vec[col[j].usz()]);
            acc = acc + product;
        }
        y[perm[i].usz()] = acc;
    }
    put32(&staged[0], 0, n.uint());
    for (usz i=0; i<n; i++) put32(&staged[0], 4+4*i, *(uint*)&y[i]);
    for (usz i=0; i<4+4*n; i++) out[i] = staged[i];
    return (4+4*n).long();
}
