#include <stddef.h>
#include <stdint.h>

enum {
    YFAST_MAX_KEYS = 256,
    YFAST_MAX_QUERIES = 256,
    YFAST_CLUSTER_SIZE = 16,
    YFAST_MAX_SEPARATORS = 16,
    YFAST_MAX_TRIE_NODES = 257,
    YFAST_UNIVERSE_BITS = 16,
    YFAST_MAX_INPUT = 514,
    YFAST_MAX_PARSEABLE = 515
};

typedef struct {
    int child[2];
    int min_rank;
    int terminal_rank;
} YFastTrieNode;

static int yfast_bucket_for(const YFastTrieNode trie[YFAST_MAX_TRIE_NODES],
                            size_t separator_count, int64_t query)
{
    int node = 0;
    int candidate = -1;
    for (int bit = YFAST_UNIVERSE_BITS - 1; bit >= 0; --bit) {
        const int query_bit = (int)((query >> bit) & 1);
        if (query_bit == 0) {
            const int right = trie[node].child[1];
            if (right >= 0 && (candidate < 0 || trie[right].min_rank < candidate))
                candidate = trie[right].min_rank;
            const int left = trie[node].child[0];
            if (left < 0) return candidate;
            node = left;
        } else {
            const int right = trie[node].child[1];
            if (right < 0) return candidate;
            node = right;
        }
    }
    if (trie[node].terminal_rank >= 0) return trie[node].terminal_rank;
    if (candidate >= 0) return candidate;
    return (int)separator_count - 1;
}

int64_t y_fast_trie_static_predecessor(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > YFAST_MAX_PARSEABLE) return -1;
    const int64_t n_value = input[0];
    const int64_t q_value = input[1];
    if (n_value < 0 || n_value > YFAST_MAX_KEYS ||
        q_value < 0 || q_value > YFAST_MAX_QUERIES) return -1;
    const size_t n = (size_t)n_value;
    const size_t query_count = (size_t)q_value;
    if (length != 2 + n + query_count || length > YFAST_MAX_INPUT) return -1;

    int64_t keys[YFAST_MAX_KEYS];
    int64_t queries[YFAST_MAX_QUERIES];
    for (size_t index = 0; index < n; ++index) {
        keys[index] = input[2 + index];
        if (keys[index] < 0 || keys[index] > 65535) return -1;
        size_t position = index;
        while (position > 0 && keys[position] < keys[position - 1]) {
            const int64_t temporary = keys[position];
            keys[position] = keys[position - 1];
            keys[position - 1] = temporary;
            --position;
        }
        if (position > 0 && keys[position] == keys[position - 1]) return -1;
    }
    for (size_t index = 0; index < query_count; ++index) {
        queries[index] = input[2 + n + index];
        if (queries[index] < 0 || queries[index] > 65535) return -1;
    }
    if (n == 0 || query_count == 0) return 0;

    const size_t separator_count = (n + YFAST_CLUSTER_SIZE - 1) / YFAST_CLUSTER_SIZE;
    int64_t separators[YFAST_MAX_SEPARATORS];
    for (size_t rank = 0; rank < separator_count; ++rank) {
        size_t end = (rank + 1) * YFAST_CLUSTER_SIZE;
        if (end > n) end = n;
        separators[rank] = keys[end - 1];
    }

    YFastTrieNode trie[YFAST_MAX_TRIE_NODES];
    for (size_t index = 0; index < YFAST_MAX_TRIE_NODES; ++index) {
        trie[index].child[0] = -1;
        trie[index].child[1] = -1;
        trie[index].min_rank = -1;
        trie[index].terminal_rank = -1;
    }
    size_t trie_size = 1;
    for (size_t rank = 0; rank < separator_count; ++rank) {
        int node = 0;
        if (trie[node].min_rank < 0 || (int)rank < trie[node].min_rank)
            trie[node].min_rank = (int)rank;
        for (int bit = YFAST_UNIVERSE_BITS - 1; bit >= 0; --bit) {
            const int branch = (int)((separators[rank] >> bit) & 1);
            int next = trie[node].child[branch];
            if (next < 0) {
                next = (int)trie_size++;
                trie[node].child[branch] = next;
            }
            node = next;
            if (trie[node].min_rank < 0 || (int)rank < trie[node].min_rank)
                trie[node].min_rank = (int)rank;
        }
        trie[node].terminal_rank = (int)rank;
    }

    int64_t checksum = 0;
    for (size_t query_index = 0; query_index < query_count; ++query_index) {
        const int64_t query = queries[query_index];
        int bucket = yfast_bucket_for(trie, separator_count, query);
        if (bucket < 0) bucket = (int)separator_count - 1;
        const size_t start = (size_t)bucket * YFAST_CLUSTER_SIZE;
        size_t end = start + YFAST_CLUSTER_SIZE;
        if (end > n) end = n;

        size_t low = start, high = end;
        while (low < high) {
            const size_t middle = low + (high - low) / 2;
            if (keys[middle] < query) low = middle + 1;
            else high = middle;
        }
        const int64_t predecessor = low > start ? keys[low - 1] :
            (start > 0 ? keys[start - 1] : -1);

        low = start;
        high = end;
        while (low < high) {
            const size_t middle = low + (high - low) / 2;
            if (keys[middle] <= query) low = middle + 1;
            else high = middle;
        }
        const int64_t successor = low < end ? keys[low] : (end < n ? keys[end] : -1);
        const int64_t contribution = (predecessor + 1) +
            INT64_C(65537) * (successor + 1);
        checksum += (int64_t)(query_index + 1) * contribution;
    }
    return checksum;
}
