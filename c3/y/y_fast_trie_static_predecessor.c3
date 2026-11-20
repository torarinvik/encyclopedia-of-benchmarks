module y_fast_trie_static_predecessor;

const int MAX_KEYS = 256;
const int MAX_QUERIES = 256;
const int CLUSTER_SIZE = 16;
const int MAX_SEPARATORS = 16;
const int MAX_TRIE_NODES = 257;
const int UNIVERSE_BITS = 16;
const usz MAX_INPUT = 514;
const usz MAX_PARSEABLE = 515;

struct TrieNode { int[2] child; int min_rank; int terminal_rank; }

fn int bucket_for(TrieNode* trie, int separator_count, long query) {
    int node = 0;
    int candidate = -1;
    for (int bit = UNIVERSE_BITS - 1; bit >= 0; bit -= 1) {
        int query_bit = (int)((query >> bit) & 1);
        if (query_bit == 0) {
            int right = trie[node].child[1];
            if (right >= 0 && (candidate < 0 || trie[right].min_rank < candidate))
                candidate = trie[right].min_rank;
            int left = trie[node].child[0];
            if (left < 0) return candidate;
            node = left;
        } else {
            int right = trie[node].child[1];
            if (right < 0) return candidate;
            node = right;
        }
    }
    if (trie[node].terminal_rank >= 0) return trie[node].terminal_rank;
    if (candidate >= 0) return candidate;
    return separator_count - 1;
}

fn long y_fast_trie_static_predecessor(long* input, usz length)
    @export("y_fast_trie_static_predecessor") {
    if (input == null || length < 2 || length > MAX_PARSEABLE) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 0 || n_value > MAX_KEYS || q_value < 0 || q_value > MAX_QUERIES)
        return -1;
    usz n = (usz)n_value, query_count = (usz)q_value;
    if (length != 2 + n + query_count || length > MAX_INPUT) return -1;

    long[MAX_KEYS] keys = zeroed;
    long[MAX_QUERIES] queries = zeroed;
    for (usz index = 0; index < n; index += 1) {
        keys[index] = input[2 + index];
        if (keys[index] < 0 || keys[index] > 65535) return -1;
    }
    for (usz index = 1; index < n; index += 1) {
        long key = keys[index];
        usz position = index;
        while (position > 0 && key < keys[position - 1]) {
            keys[position] = keys[position - 1];
            position -= 1;
        }
        keys[position] = key;
    }
    for (usz index = 1; index < n; index += 1)
        if (keys[index] == keys[index - 1]) return -1;
    for (usz index = 0; index < query_count; index += 1) {
        queries[index] = input[2 + n + index];
        if (queries[index] < 0 || queries[index] > 65535) return -1;
    }
    if (n == 0 || query_count == 0) return 0;

    int separator_count = (int)((n + CLUSTER_SIZE - 1) / CLUSTER_SIZE);
    long[MAX_SEPARATORS] separators;
    for (int rank = 0; rank < separator_count; rank += 1) {
        usz end = (usz)(rank + 1) * CLUSTER_SIZE;
        if (end > n) end = n;
        separators[rank] = keys[end - 1];
    }

    TrieNode[MAX_TRIE_NODES] trie;
    for (int node = 0; node < MAX_TRIE_NODES; node += 1) {
        trie[node].child[0] = -1;
        trie[node].child[1] = -1;
        trie[node].min_rank = -1;
        trie[node].terminal_rank = -1;
    }
    int trie_size = 1;
    for (int rank = 0; rank < separator_count; rank += 1) {
        int node = 0;
        if (trie[node].min_rank < 0 || rank < trie[node].min_rank)
            trie[node].min_rank = rank;
        for (int bit = UNIVERSE_BITS - 1; bit >= 0; bit -= 1) {
            int branch = (int)((separators[rank] >> bit) & 1);
            int next = trie[node].child[branch];
            if (next < 0) {
                next = trie_size;
                trie_size += 1;
                trie[node].child[branch] = next;
            }
            node = next;
            if (trie[node].min_rank < 0 || rank < trie[node].min_rank)
                trie[node].min_rank = rank;
        }
        trie[node].terminal_rank = rank;
    }

    long checksum = 0;
    for (usz query_index = 0; query_index < query_count; query_index += 1) {
        long query = queries[query_index];
        int bucket = bucket_for(&trie[0], separator_count, query);
        if (bucket < 0) bucket = separator_count - 1;
        usz start = (usz)bucket * CLUSTER_SIZE;
        usz end = start + CLUSTER_SIZE;
        if (end > n) end = n;

        usz low = start, high = end;
        while (low < high) {
            usz middle = low + (high - low) / 2;
            if (keys[middle] < query) low = middle + 1;
            else high = middle;
        }
        long predecessor = low > start ? keys[low - 1] : (start > 0 ? keys[start - 1] : -1);

        low = start;
        high = end;
        while (low < high) {
            usz middle = low + (high - low) / 2;
            if (keys[middle] <= query) low = middle + 1;
            else high = middle;
        }
        long successor = low < end ? keys[low] : (end < n ? keys[end] : -1);
        long contribution = (predecessor + 1) + 65537L * (successor + 1);
        checksum += (long)(query_index + 1) * contribution;
    }
    return checksum;
}
