module divide_conquer_tangent_hull;

// Unverified divide-and-conquer tangent-merge hull draft.
fn long cross(long* x, long* y, usz a, usz b, usz c) {
    return (x[b]-x[a])*(y[c]-y[a]) - (y[b]-y[a])*(x[c]-x[a]);
}
fn usz chain(long* x, long* y, usz* order, usz* out, usz lo, usz hi, usz base, bool upper) {
    if (hi-lo == 1) { out[base] = order[lo]; return 1; }
    usz middle = lo+(hi-lo)/2, left_capacity = middle-lo;
    usz left_n = chain(x, y, order, out, lo, middle, base, upper);
    usz right_n = chain(x, y, order, out, middle, hi, base+left_capacity, upper);
    usz i = left_n-1, j = 0;
    bool changed = true;
    while (changed) {
        changed = false;
        while (i > 0) {
            long sign = cross(x, y, out[base+i], out[base+left_capacity+j], out[base+i-1]);
            if (upper ? sign <= 0 : sign >= 0) break;
            i--; changed = true;
        }
        while (j+1 < right_n) {
            long sign = cross(x, y, out[base+i], out[base+left_capacity+j], out[base+left_capacity+j+1]);
            if (upper ? sign <= 0 : sign >= 0) break;
            j++; changed = true;
        }
    }
    usz suffix = right_n-j;
    for (usz k = 0; k < suffix; k++) out[base+i+1+k] = out[base+left_capacity+j+k];
    return i+1+suffix;
}

fn long divide_conquer_tangent_hull(long* input, usz length, char* output, usz capacity) @export("divide_conquer_tangent_hull") {
    if (input == null || length < 7 || length > 66 || input[0] < 3 || input[0] > 32) return -1;
    usz n = (usz)input[0];
    if (length != 1+2*n) return -1;
    long[32] x, y;
    usz[32] order, scratch;
    for (usz i = 0; i < n; i++) {
        x[i] = input[1+2*i]; y[i] = input[2+2*i];
        if (x[i] < -1000 || x[i] > 1000 || y[i] < -1000 || y[i] > 1000) return -1;
        for (usz j = 0; j < i; j++) if (x[j] == x[i]) return -1;
        order[i] = i;
    }
    for (usz i = 0; i < n; i++) for (usz j = i+1; j < n; j++) for (usz k = j+1; k < n; k++)
        if (cross(&x[0], &y[0], i, j, k) == 0) return -1;
    for (usz width = 1; width < n; width *= 2) {
        for (usz begin = 0; begin < n; begin += 2*width) {
            usz middle = begin+width < n ? begin+width : n;
            usz end = begin+2*width < n ? begin+2*width : n;
            usz left = begin, right = middle, dest = begin;
            while (left < middle && right < end)
                scratch[dest++] = x[order[right]] < x[order[left]] ? order[right++] : order[left++];
            while (left < middle) scratch[dest++] = order[left++];
            while (right < end) scratch[dest++] = order[right++];
        }
        for (usz i = 0; i < n; i++) order[i] = scratch[i];
    }
    usz[32] lower, upper, hull;
    usz lower_n = chain(&x[0], &y[0], &order[0], &lower[0], 0, n, 0, false);
    usz upper_n = chain(&x[0], &y[0], &order[0], &upper[0], 0, n, 0, true);
    usz count = 0;
    for (usz i = 0; i < lower_n; i++) hull[count++] = lower[i];
    for (usz i = upper_n-1; i > 1;) hull[count++] = upper[--i];
    usz bytes = 16*count;
    if (output == null || capacity < bytes) return -2;
    for (usz i = 0; i < count; i++) {
        ulong[2] words = {(ulong)x[hull[i]], (ulong)y[hull[i]]};
        for (usz axis = 0; axis < 2; axis++) for (usz b = 0; b < 8; b++)
            output[16*i+8*axis+b] = (char)(words[axis] >> (8*b));
    }
    return (long)bytes;
}
