// Uncompiled monotone-cursor Prüfer decoder draft.
module prufer_decode_linear;
fn void pdl_write(char* output, usz offset, ulong value) {
    for (usz i = 0; i < 8; i++) output[offset+i] = (char)((value >> (8*i)) & 255);
}
fn long prufer_decode_linear(long* input, usz length, char* output, usz capacity) @export("prufer_decode_linear") {
    if (input == null || length < 1 || length > 4096) return -1;
    long nv = input[0];
    if (nv < 2 || nv > 4096 || length != (usz)(nv-1)) return -1;
    usz n = (usz)nv;
    int[4096] count = zeroed;
    for (usz i = 1; i < length; i++) {
        if (input[i] < 0 || input[i] >= nv) return -1;
        count[(usz)input[i]]++;
    }
    usz needed = 16*(n-1);
    if (output == null || capacity < needed) return -2;
    int cursor = (int)n-1;
    while (count[cursor] != 0) cursor--;
    int leaf = cursor;
    for (usz i = 1; i < length; i++) {
        int v = (int)input[i];
        pdl_write(output, 16*(i-1), (ulong)leaf); pdl_write(output, 16*(i-1)+8, (ulong)v);
        count[leaf] = -1; count[v]--;
        if (count[v] == 0 && v > cursor) leaf = v;
        else { cursor--; while (count[cursor] != 0) cursor--; leaf = cursor; }
    }
    int other = 0;
    while (other == leaf || count[other] != 0) other++;
    pdl_write(output, 16*(n-2), (ulong)leaf); pdl_write(output, 16*(n-2)+8, (ulong)other);
    return (long)needed;
}
