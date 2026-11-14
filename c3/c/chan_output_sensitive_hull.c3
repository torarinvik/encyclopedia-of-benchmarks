module chan_output_sensitive_hull;

// Unverified Chan hull draft. No compiler or benchmark has run.
fn long turn(long* x, long* y, usz a, usz b, usz c) {
    return (x[b]-x[a])*(y[c]-y[a]) - (y[b]-y[a])*(x[c]-x[a]);
}
fn bool less(long* x, long* y, usz a, usz b) {
    return x[a] < x[b] || (x[a] == x[b] && y[a] < y[b]);
}
fn usz group_hull(long* x, long* y, usz begin, usz count, usz* output) {
    usz[32] order, scratch;
    usz[64] chain;
    for (usz i = 0; i < count; i++) order[i] = begin+i;
    for (usz width = 1; width < count; width *= 2) {
        for (usz block = 0; block < count; block += 2*width) {
            usz middle = block+width < count ? block+width : count;
            usz end = block+2*width < count ? block+2*width : count;
            usz left = block, right = middle, dest = block;
            while (left < middle && right < end) {
                if (less(x, y, order[right], order[left])) scratch[dest++] = order[right++];
                else scratch[dest++] = order[left++];
            }
            while (left < middle) scratch[dest++] = order[left++];
            while (right < end) scratch[dest++] = order[right++];
        }
        for (usz i = 0; i < count; i++) order[i] = scratch[i];
    }
    if (count == 1) { output[0] = order[0]; return 1; }
    usz used = 0;
    for (usz i = 0; i < count; i++) {
        while (used >= 2 && turn(x, y, chain[used-2], chain[used-1], order[i]) <= 0) used--;
        chain[used++] = order[i];
    }
    usz lower = used;
    for (usz i = count-1; i > 0;) {
        i--;
        while (used > lower && turn(x, y, chain[used-2], chain[used-1], order[i]) <= 0) used--;
        chain[used++] = order[i];
    }
    used--;
    for (usz i = 0; i < used; i++) output[i] = chain[i];
    return used;
}
fn usz tangent(long* x, long* y, usz* hull, usz n, usz query) {
    if (n == 1) return hull[0];
    if (n == 2) return turn(x, y, query, hull[0], hull[1]) > 0 ? hull[0] : hull[1];
    bool initial_up = turn(x, y, query, hull[0], hull[1]) > 0;
    usz lo = 0, hi = n;
    while (lo < hi) {
        usz mid = lo + (hi-lo)/2;
        bool before = turn(x, y, query, hull[mid], hull[(mid+n-1)%n]) > 0;
        bool after = turn(x, y, query, hull[mid], hull[(mid+1)%n]) > 0;
        if (before && after) return hull[mid];
        bool below = mid != 0 && turn(x, y, query, hull[mid], hull[0]) > 0;
        bool above = mid != 0 && turn(x, y, query, hull[0], hull[mid]) > 0;
        bool search_left = initial_up ? (after && below) : (after || above);
        if (search_left) hi = mid; else lo = mid+1;
    }
    return 32;
}
fn long chan_output_sensitive_hull(long* input, usz length, char* output, usz capacity) @export("chan_output_sensitive_hull") {
    if (input == null || length < 7 || length > 66 || input[0] < 3 || input[0] > 32) return -1;
    usz n = (usz)input[0];
    if (length != 1+2*n) return -1;
    long[32] x, y;
    for (usz i = 0; i < n; i++) {
        x[i] = input[1+2*i]; y[i] = input[2+2*i];
        if (x[i] < -1000 || x[i] > 1000 || y[i] < -1000 || y[i] > 1000) return -1;
        for (usz j = 0; j < i; j++) if (x[i] == x[j] && y[i] == y[j]) return -1;
    }
    for (usz i = 0; i < n; i++) for (usz j = i+1; j < n; j++) for (usz k = j+1; k < n; k++)
        if (turn(&x[0], &y[0], i, j, k) == 0) return -1;
    usz start = 0;
    for (usz i = 1; i < n; i++) if (less(&x[0], &y[0], i, start)) start = i;
    usz guess = n < 4 ? n : 4;
    while (true) {
        usz[32] hulls, offsets, sizes, group_of, position;
        usz groups = 0, stored = 0;
        for (usz begin = 0; begin < n;) {
            usz end = begin+guess < n ? begin+guess : n;
            offsets[groups] = stored;
            sizes[groups] = group_hull(&x[0], &y[0], begin, end-begin, &hulls[stored]);
            for (usz i = begin; i < end; i++) { group_of[i] = groups; position[i] = 32; }
            for (usz i = 0; i < sizes[groups]; i++) position[hulls[stored+i]] = i;
            stored += sizes[groups]; groups++; begin = end;
        }
        usz[32] result;
        result[0] = start;
        usz used = 1;
        for (usz step = 0; step < guess; step++) {
            usz current = result[used-1], candidate = 32;
            for (usz g = 0; g < groups; g++) {
                usz local = 32;
                if (g == group_of[current]) {
                    if (position[current] == 32) return -1;
                    if (sizes[g] > 1) local = hulls[offsets[g]+(position[current]+1)%sizes[g]];
                } else {
                    local = tangent(&x[0], &y[0], &hulls[offsets[g]], sizes[g], current);
                    if (local == 32) return -1;
                }
                if (local != 32 && (candidate == 32 || turn(&x[0], &y[0], current, candidate, local) < 0)) candidate = local;
            }
            if (candidate == 32) return -1;
            if (candidate == start) {
                usz bytes = 16*used;
                if (output == null || capacity < bytes) return -2;
                for (usz i = 0; i < used; i++) {
                    ulong[2] fields = {(ulong)x[result[i]], (ulong)y[result[i]]};
                    for (usz axis = 0; axis < 2; axis++) for (usz b = 0; b < 8; b++)
                        output[16*i+8*axis+b] = (char)(fields[axis] >> (8*b));
                }
                return (long)bytes;
            }
            if (used == n) return -1;
            result[used++] = candidate;
        }
        if (guess == n) return -1;
        guess = guess*guess < n ? guess*guess : n;
    }
}
