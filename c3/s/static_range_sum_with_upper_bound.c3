module static_range_sum_with_upper_bound;

fn long static_range_sum_with_upper_bound(long* input, usz length, uchar* output, usz capacity)
        @export("static_range_sum_with_upper_bound") {
    if (input == null || length < 2 || length > 258) return -1;
    if (input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > 64) return -1;
    int n = (int)input[0], q = (int)input[1];
    if (length != (usz)(2+n+3*q)) return -1;
    long[64] current = {}, scratch = {};
    for (int i = 0; i < n; i++) {
        if (input[2+i] < 0 || input[2+i] > 1000000000) return -1;
        current[i] = input[2+i];
    }
    for (int i = 0; i < q; i++) {
        int b = 2+n+3*i;
        if (input[b] < 0 || input[b] > input[b+1] || input[b+1] > n || input[b+2] < 0 || input[b+2] > 1000000000) return -1;
    }
    if (output == null || capacity < (usz)(16*q)) return -2;
    int[1950] counts = {};
    int[30] offsets = {};
    long[1950] sums = {};
    for (int level = 0; level < 30; level++) {
        long mask = 1L << (29-level);
        for (int i = 0; i < n; i++) {
            bool zero = (current[i] & mask) == 0;
            counts[65*level+i+1] = counts[65*level+i] + (zero ? 1 : 0);
            sums[65*level+i+1] = sums[65*level+i] + (zero ? current[i] : 0);
        }
        offsets[level] = counts[65*level+n];
        int z = 0, o = offsets[level];
        for (int i = 0; i < n; i++) {
            if ((current[i] & mask) == 0) scratch[z++] = current[i];
            else scratch[o++] = current[i];
        }
        for (int i = 0; i < n; i++) current[i] = scratch[i];
    }
    for (int i = 0; i < q; i++) {
        int b = 2+n+3*i, l = (int)input[b], r = (int)input[b+1];
        long key = input[b+2]+1, count = 0, sum = 0;
        for (int level = 0; level < 30; level++) {
            int zl = counts[65*level+l], zr = counts[65*level+r];
            if ((key & (1L << (29-level))) != 0) {
                count += zr-zl; sum += sums[65*level+r]-sums[65*level+l];
                l += offsets[level]-zl; r += offsets[level]-zr;
            } else { l = zl; r = zr; }
        }
        for (int byte = 0; byte < 8; byte++) {
            output[16*i+byte] = (uchar)((count >> (8*byte)) & 255);
            output[16*i+8+byte] = (uchar)((sum >> (8*byte)) & 255);
        }
    }
    return 16*q;
}
