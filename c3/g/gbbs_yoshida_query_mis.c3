// Clean-room GBBS Yoshida recursive MIS query; see package LICENSE.txt.
module gbbs_yoshida_query_mis;

const usz MAX_N = 12;
const usz MAX_M = 24;
const usz MAX_INPUT = 52;
const usz MAX_CUTOFF = 128;

fn ulong hash64(ulong value) {
    ulong mixed = value * 3935559000370003845ul + 2691343689449507681ul;
    mixed ^= mixed >> 21;
    mixed ^= mixed << 37;
    mixed ^= mixed >> 4;
    mixed *= 4768777513237032717ul;
    mixed ^= mixed << 20;
    mixed ^= mixed >> 41;
    mixed ^= mixed << 5;
    return mixed;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long query(usz vertex, usz* degree, usz* neighbors, ulong* priority,
              usz* work, usz cutoff) {
    for (usz index = 0; index < degree[vertex]; index += 1) {
        if (*work == cutoff) return -1;
        usz neighbor = neighbors[vertex * MAX_N + index];
        *work += 1;
        if (priority[vertex] < priority[neighbor] ||
            (priority[vertex] == priority[neighbor] && vertex <= neighbor)) break;
        long status = query(neighbor, degree, neighbors, priority, work, cutoff);
        if (status == 1) return 0;
        if (status == -1) return -1;
    }
    return 1;
}

long gbbs_yoshida_query_mis(long* input, usz length, char* output, usz capacity)
        @export("gbbs_yoshida_query_mis") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1], root64 = input[2], cutoff64 = input[3];
    if (n64 < 1 || n64 > 12 || m64 < 0 || m64 > 24 ||
        root64 < 0 || root64 >= n64 || cutoff64 < 0 || cutoff64 > 128 ||
        length != 4 + 2 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64;
    bool[MAX_N * MAX_N] adjacent = zeroed;
    usz[MAX_N] degree = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[4 + 2 * edge], v64 = input[5 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacent[u * MAX_N + v]) return -1;
        adjacent[u * MAX_N + v] = true;
        adjacent[v * MAX_N + u] = true;
        degree[u] += 1;
        degree[v] += 1;
    }
    if (output == null || capacity < 16) return -2;
    ulong[MAX_N] priority = zeroed;
    usz[MAX_N * MAX_N] neighbors = zeroed;
    for (usz vertex = 0; vertex < n; vertex += 1) priority[vertex] = hash64((ulong)vertex);
    for (usz vertex = 0; vertex < n; vertex += 1) {
        usz inserted = 0;
        for (usz other = 0; other < n; other += 1) if (adjacent[vertex * MAX_N + other]) {
            usz position = inserted;
            while (position > 0) {
                usz previous = neighbors[vertex * MAX_N + position - 1];
                if (priority[previous] < priority[other] ||
                    (priority[previous] == priority[other] && previous < other)) break;
                neighbors[vertex * MAX_N + position] = previous;
                position -= 1;
            }
            neighbors[vertex * MAX_N + position] = other;
            inserted += 1;
        }
    }
    usz work = 0;
    long status = query((usz)root64, &degree[0], &neighbors[0], &priority[0],
                        &work, (usz)cutoff64);
    store_i64_le(output, 0, status);
    store_i64_le(output, 8, (long)work);
    return 16;
}
