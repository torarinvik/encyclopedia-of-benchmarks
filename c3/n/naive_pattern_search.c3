module naive_pattern_search;
fn long naive_pattern_search(long* v, usz n) @export("naive_pattern_search") {
    if (v == null || n < 2 || n > 512) return -2;
    long tn=v[0], pn=v[1];
    if (tn < 0 || tn > 255 || pn < 0 || pn > tn || n != (usz)(2+tn+pn)) return -2;
    for (usz i=0; i<(usz)(tn+pn); ++i) if (v[2+i] < 0 || v[2+i] > 127) return -2;
    if (pn == 0) return -1;
    for (long start=0; start<=tn-pn; ++start) {
        long j=0;
        while (j<pn && v[2+start+j]==v[2+tn+j]) ++j;
        if (j==pn) return start;
    }
    return -1;
}
