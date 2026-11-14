module melkman_simple_polyline_hull;

fn long turn(long* x, long* y, usz a, usz b, usz c) {
    return (x[b]-x[a])*(y[c]-y[a])-(y[b]-y[a])*(x[c]-x[a]);
}

long melkman_simple_polyline_hull(long* input, usz length, char* output, usz capacity)
        @export("melkman_simple_polyline_hull") {
    if (input == null || length < 7 || length > 66) return -1;
    long raw = input[0];
    if (raw < 3 || raw > 32) return -1;
    usz n = raw.usz();
    if (length != 1+2*n) return -1;
    long[32] x = zeroed, y = zeroed;
    for (usz i = 0; i < n; i += 1) {
        x[i] = input[1+2*i]; y[i] = input[2+2*i];
        if (x[i] < -1000 || x[i] > 1000 || y[i] < -1000 || y[i] > 1000) return -1;
    }
    long initial = turn(&x[0], &y[0], 0, 1, 2);
    if (initial == 0) return -1;
    usz[68] deque = zeroed;
    usz first = 32, last = 35;
    deque[32] = 2; deque[35] = 2;
    deque[33] = initial > 0 ? 0 : 1;
    deque[34] = initial > 0 ? 1 : 0;
    for (usz i = 3; i < n; i += 1) {
        if (turn(&x[0],&y[0],deque[first],deque[first+1],i) > 0 && turn(&x[0],&y[0],deque[last-1],deque[last],i) > 0) continue;
        while (last > first && turn(&x[0],&y[0],deque[first],deque[first+1],i) <= 0) first += 1;
        if (last <= first || first == 0) return -1;
        first -= 1; deque[first] = i;
        while (last > first && turn(&x[0],&y[0],deque[last-1],deque[last],i) <= 0) last -= 1;
        if (last <= first || last+1 >= 68) return -1;
        last += 1; deque[last] = i;
    }
    usz count = last-first, start = 0;
    for (usz i = 1; i < count; i += 1) {
        usz a = deque[first+i], b = deque[first+start];
        if (x[a] < x[b] || (x[a] == x[b] && y[a] < y[b])) start = i;
    }
    usz bytes = 8*count;
    if (output == null || capacity < bytes) return -2;
    char[256] staged = zeroed;
    for (usz i = 0; i < count; i += 1) {
        ulong index = (ulong)deque[first+(start+i)%count];
        for (usz b = 0; b < 8; b += 1) { staged[8*i+b] = (char)(index & 255); index >>= 8; }
    }
    for (usz i = 0; i < bytes; i += 1) output[i] = staged[i];
    return bytes.long();
}
