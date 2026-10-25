// Clean-room port of TSVC s424; see package README for provenance and rights.
module tsvc_s424_alias_overlap_feedback;

const usz MIN_N = 66;
const usz MAX_N = 192;
const usz X_LENGTH = 255;

long tsvc_s424_alias_overlap_feedback(long* input, usz length)
        @export("tsvc_s424_alias_overlap_feedback") {
    if (input == null || length < 130 || length > 256) return -1;
    if (input[0] < (long)MIN_N || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != n + 64) return -1;
    long[MAX_N] a;
    long[X_LENGTH] x;
    for (usz i = 0; i < n; i++) {
        a[i] = input[1 + i];
        if (a[i] < 0 || a[i] > 10) return -1;
    }
    for (usz i = 0; i < 63; i++) {
        x[i] = input[1 + n + i];
        if (x[i] < 0 || x[i] > 10) return -1;
    }
    for (usz i = 63; i < X_LENGTH; i++) x[i] = 0;
    for (usz i = 0; i < n - 1; i++) x[i + 64] = x[i] + a[i];
    long checksum = 0;
    for (usz i = 0; i < n; i++) checksum += x[63 + i];
    return checksum;
}
