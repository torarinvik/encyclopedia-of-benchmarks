module elementary;
fn long elementary(long *v, usz n, char *out, usz cap) @export("elementary") {
    if (v == null || n < 2 || n > 129) return -1;
    long count = v[0];
    if (count < 1 || count > 128 || n != (usz)(count + 1) || v[1] != 0) return -1;
    for (usz i = 1; i < n; i++) if (v[i] != 0 && v[i] != 1) return -1;
    if (cap < (usz)count || out == null) return -2;
    for (usz i = 0; i < (usz)count; i++) {
        uint l = i > 0 ? (uint)v[i] : 0;
        uint c = (uint)v[i + 1];
        uint r = i + 1 < (usz)count ? (uint)v[i + 2] : 0;
        out[i] = (char)((30 >> (l * 4 + c * 2 + r)) & 1);
    }
    return count;
}
