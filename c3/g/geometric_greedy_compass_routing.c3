module geometric_greedy_compass_routing;
const usz MAX_N = 8; const usz MAX_INPUT = 84; const usz MAX_OUTPUT = 80; const usz OUTPUT_VALUES = 10;

fn void put64(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[position + byte] = (char)(bits & 255); bits >>= 8; }
}
fn bool angle_better(long da, long la, long db, long lb) {
    if ((da >= 0) != (db >= 0)) return da >= 0;
    long left = da * da * lb, right = db * db * la;
    if (da >= 0) return left > right;
    return left < right;
}
fn bool angle_equal(long da, long la, long db, long lb) {
    return (da >= 0) == (db >= 0) && da * da * lb == db * db * la;
}

long geometric_greedy_compass_routing(long* input, usz length, char* output, usz capacity) @export("geometric_greedy_compass_routing") {
    if (input == null || length < 12 || length > MAX_INPUT) return -1;
    long n64 = input[0], mode = input[1], source64 = input[2], target64 = input[3];
    if (n64 < 2 || n64 > (long)MAX_N || mode < 0 || mode > 1 || source64 < 0 || target64 < 0 || source64 >= n64 || target64 >= n64) return -1;
    usz n = (usz)n64, source = (usz)source64, target = (usz)target64;
    if (length != 4 + 2*n + n*n) return -1;
    long[MAX_N] x = zeroed, y = zeroed;
    usz adjacency = 4 + 2*n;
    for (usz i = 0; i < n; i += 1) {
        x[i] = input[4+i]; y[i] = input[4+n+i];
        if (x[i] < -8 || x[i] > 8 || y[i] < -8 || y[i] > 8) return -1;
        for (usz j = 0; j < i; j += 1) if (x[i] == x[j] && y[i] == y[j]) return -1;
    }
    for (usz i = 0; i < n; i += 1) for (usz j = 0; j < n; j += 1) {
        long a = input[adjacency+i*n+j], b = input[adjacency+j*n+i];
        if ((a != 0 && a != 1) || a != b || (i == j && a != 0)) return -1;
    }
    if (output == null || capacity < MAX_OUTPUT) return -2;
    usz[MAX_N] path = zeroed; bool[MAX_N] visited = zeroed; usz count = 1;
    path[0] = source; visited[source] = true; usz current = source;
    while (current != target && count < n) {
        usz best = n; long best_dot = 0, best_len = 1, best_distance = 0;
        long tx = x[target]-x[current], ty = y[target]-y[current];
        for (usz v = 0; v < n; v += 1) {
            if (input[adjacency+current*n+v] != 1) continue;
            bool better = best == n;
            long dx = x[v]-x[current], dy = y[v]-y[current];
            if (mode == 0) {
                long rx = x[v]-x[target], ry = y[v]-y[target], distance = rx*rx+ry*ry;
                if (!better) better = distance < best_distance || (distance == best_distance && v < best);
                if (better) best_distance = distance;
            } else {
                long dot = dx*tx+dy*ty, len = dx*dx+dy*dy;
                if (!better) better = angle_better(dot,len,best_dot,best_len) || (angle_equal(dot,len,best_dot,best_len) && v < best);
                if (better) { best_dot = dot; best_len = len; }
            }
            if (better) best = v;
        }
        if (best == n || visited[best]) break;
        path[count] = best; count += 1; visited[best] = true; current = best;
    }
    long[OUTPUT_VALUES] record = zeroed;
    record[0] = current == target ? 1 : 0; record[1] = (long)(count-1);
    for (usz i = 0; i < MAX_N; i += 1) record[2+i] = -1;
    for (usz i = 0; i < count; i += 1) record[2+i] = (long)path[i];
    char[MAX_OUTPUT] staged = zeroed;
    for (usz i = 0; i < OUTPUT_VALUES; i += 1) put64(&staged[0],8*i,record[i]);
    for (usz i = 0; i < MAX_OUTPUT; i += 1) output[i] = staged[i];
    return (long)MAX_OUTPUT;
}
