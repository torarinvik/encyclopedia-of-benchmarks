module x_fast_trie_static_predecessor;

const int MAX_KEYS = 24;
const int MAX_QUERIES = 24;
const int UNIVERSE_BITS = 16;
const int LEVELS = 17;
const usz MAX_PARSEABLE = 51;

fn long prefix_of(long key, usz depth) {
    return depth == 0 ? 0 : key >> (UNIVERSE_BITS - (int)depth);
}

fn int find_prefix(long* prefixes, usz* counts, usz depth, long wanted) {
    usz low = 0, high = counts[depth];
    while (low < high) {
        usz middle = low + (high - low) / 2;
        long value = prefixes[depth * MAX_KEYS + middle];
        if (value < wanted) low = middle + 1; else high = middle;
    }
    if (low < counts[depth] && prefixes[depth * MAX_KEYS + low] == wanted) return (int)low;
    return -1;
}

fn long xfast_predecessor(long* prefixes, long* maxima, usz* counts, long query) {
    usz low = 0, high = LEVELS;
    while (high - low > 1) {
        usz middle = low + (high - low) / 2;
        if (find_prefix(prefixes, counts, middle, prefix_of(query, middle)) >= 0) low = middle;
        else high = middle;
    }
    if (low == UNIVERSE_BITS) return query;
    usz depth = low + 1;
    while (depth > 0) {
        long query_prefix = query >> (UNIVERSE_BITS - (int)depth);
        if ((query_prefix & 1) != 0) {
            int sibling = find_prefix(prefixes, counts, depth, query_prefix - 1);
            if (sibling >= 0) return maxima[depth * MAX_KEYS + (usz)sibling];
        }
        depth -= 1;
    }
    return -1;
}

fn long x_fast_trie_static_predecessor(long* input, usz length)
    @export("x_fast_trie_static_predecessor") {
    if (input == null || length < 2 || length > MAX_PARSEABLE) return -1;
    if (input[0] < 0 || input[0] > MAX_KEYS || input[1] < 0 || input[1] > MAX_QUERIES) return -1;
    usz n = (usz)input[0], q = (usz)input[1];
    if (length != 2 + n + q) return -1;
    long[MAX_KEYS] keys = zeroed;
    long[MAX_QUERIES] queries = zeroed;
    for (usz i = 0; i < n; i++) {
        keys[i] = input[2 + i];
        if (keys[i] < 0 || keys[i] > 65535) return -1;
    }
    for (usz i = 1; i < n; i++) {
        long key = keys[i];
        usz at = i;
        while (at > 0 && key < keys[at - 1]) { keys[at] = keys[at - 1]; at -= 1; }
        keys[at] = key;
    }
    for (usz i = 1; i < n; i++) if (keys[i] == keys[i - 1]) return -1;
    for (usz i = 0; i < q; i++) {
        queries[i] = input[2 + n + i];
        if (queries[i] < 0 || queries[i] > 65535) return -1;
    }
    if (n == 0 || q == 0) return 0;

    long[LEVELS * MAX_KEYS] prefixes = zeroed, maxima = zeroed;
    usz[LEVELS] counts = zeroed;
    for (usz depth = 0; depth < LEVELS; depth++) {
        for (usz i = 0; i < n; i++) {
            long value = prefix_of(keys[i], depth);
            usz row = depth * MAX_KEYS;
            if (counts[depth] == 0 || prefixes[row + counts[depth] - 1] != value) {
                prefixes[row + counts[depth]] = value;
                maxima[row + counts[depth]] = keys[i];
                counts[depth] += 1;
            } else maxima[row + counts[depth] - 1] = keys[i];
        }
    }
    long checksum = 0;
    for (usz i = 0; i < q; i++)
        checksum += (long)(i + 1) * (xfast_predecessor(&prefixes[0], &maxima[0], &counts[0], queries[i]) + 1);
    return checksum;
}
