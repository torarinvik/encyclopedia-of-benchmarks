#include <stddef.h>
#include <stdint.h>

enum { MAX_KEYS = 24, MAX_QUERIES = 24, UNIVERSE_BITS = 16, LEVELS = 17, MAX_INPUT = 50, MAX_PARSEABLE = 51 };

static int64_t prefix_of(int64_t key, size_t depth) {
    return depth == 0 ? 0 : key >> (UNIVERSE_BITS - depth);
}

static int find_prefix(const int64_t prefixes[LEVELS][MAX_KEYS], const size_t counts[LEVELS],
                       size_t depth, int64_t wanted) {
    size_t low = 0, high = counts[depth];
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        if (prefixes[depth][middle] < wanted) low = middle + 1;
        else high = middle;
    }
    return low < counts[depth] && prefixes[depth][low] == wanted ? (int)low : -1;
}

static int64_t xfast_predecessor(const int64_t prefixes[LEVELS][MAX_KEYS],
        const int64_t maxima[LEVELS][MAX_KEYS], const size_t counts[LEVELS], int64_t query) {
    size_t low = 0, high = LEVELS;
    while (high - low > 1) {
        const size_t middle = low + (high - low) / 2;
        if (find_prefix(prefixes, counts, middle, prefix_of(query, middle)) >= 0) low = middle;
        else high = middle;
    }
    if (low == UNIVERSE_BITS) return query;
    size_t depth = low + 1;
    while (depth > 0) {
        const size_t shift = UNIVERSE_BITS - depth;
        const int64_t query_prefix = query >> shift;
        if ((query_prefix & 1) != 0) {
            const int sibling = find_prefix(prefixes, counts, depth, query_prefix - 1);
            if (sibling >= 0) return maxima[depth][(size_t)sibling];
        }
        --depth;
    }
    return -1;
}

int64_t x_fast_trie_static_predecessor(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE) return -1;
    if (input[0] < 0 || input[0] > MAX_KEYS || input[1] < 0 || input[1] > MAX_QUERIES) return -1;
    const size_t n = (size_t)input[0], q = (size_t)input[1];
    if (length != 2 + n + q || length > MAX_INPUT) return -1;
    int64_t keys[MAX_KEYS] = {0}, queries[MAX_QUERIES] = {0};
    for (size_t i = 0; i < n; ++i) {
        keys[i] = input[2 + i];
        if (keys[i] < 0 || keys[i] > 65535) return -1;
        size_t at = i;
        while (at > 0 && keys[at] < keys[at - 1]) {
            const int64_t temporary = keys[at]; keys[at] = keys[at - 1]; keys[at - 1] = temporary;
            --at;
        }
        if (at > 0 && keys[at] == keys[at - 1]) return -1;
    }
    for (size_t i = 0; i < q; ++i) {
        queries[i] = input[2 + n + i];
        if (queries[i] < 0 || queries[i] > 65535) return -1;
    }
    if (n == 0 || q == 0) return 0;

    int64_t prefixes[LEVELS][MAX_KEYS] = {{0}}, maxima[LEVELS][MAX_KEYS] = {{0}};
    size_t counts[LEVELS] = {0};
    for (size_t depth = 0; depth < LEVELS; ++depth) {
        for (size_t i = 0; i < n; ++i) {
            const int64_t value = prefix_of(keys[i], depth);
            if (counts[depth] == 0 || prefixes[depth][counts[depth] - 1] != value) {
                prefixes[depth][counts[depth]] = value;
                maxima[depth][counts[depth]] = keys[i];
                ++counts[depth];
            } else {
                maxima[depth][counts[depth] - 1] = keys[i];
            }
        }
    }
    int64_t checksum = 0;
    for (size_t i = 0; i < q; ++i)
        checksum += (int64_t)(i + 1) * (xfast_predecessor(prefixes, maxima, counts, queries[i]) + 1);
    return checksum;
}
