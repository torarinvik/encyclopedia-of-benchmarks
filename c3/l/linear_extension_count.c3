module linear_extension_count;

const usz MAX_N = 12;
const usz MAX_LENGTH = 14;
const usz MAX_STATES = 4096;

fn long linear_extension_count(long* input, usz length)
        @export("linear_extension_count") {
    if (input == null || length < 1 || length > MAX_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != n + 1) return -1;
    usz full = ((usz)1 << n) - 1;
    usz[MAX_N] predecessor = zeroed;
    for (usz vertex = 0; vertex < n; vertex++) {
        if (input[1 + vertex] < 0 || (usz)input[1 + vertex] > full) return -1;
        predecessor[vertex] = (usz)input[1 + vertex];
    }
    long[MAX_STATES] ways = zeroed;
    ways[0] = 1;
    for (usz prefix = 0; prefix <= full; prefix++) {
        long count = ways[prefix];
        if (count == 0) continue;
        for (usz vertex = 0; vertex < n; vertex++) {
            usz bit = (usz)1 << vertex;
            if ((prefix & bit) == 0 && (predecessor[vertex] & prefix) == predecessor[vertex])
                ways[prefix | bit] += count;
        }
    }
    return ways[full];
}
