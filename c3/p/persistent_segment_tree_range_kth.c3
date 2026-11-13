module persistent_segment_tree_range_kth;

const usz MAX_N = 32;
const usz MAX_Q = 32;
const usz MAX_INPUT_LENGTH = 131;
const usz MAX_NODES = 193;
const long INVALID_RESULT = -9223372036854775807L - 1L;

fn int lower_bound_i64(long* values, usz length, long target) {
    usz low = 0;
    usz high = length;
    while (low < high) {
        usz middle = low + (high - low) / 2;
        if (values[middle] < target) low = middle + 1;
        else high = middle;
    }
    return (int)low;
}

fn long persistent_segment_tree_range_kth(long* input, usz length)
        @export("persistent_segment_tree_range_kth") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    if (input[0] < 1 || input[0] > (long)MAX_N || input[1] < 0 || input[1] > (long)MAX_Q) return INVALID_RESULT;
    usz n = (usz)input[0];
    usz q = (usz)input[1];
    if (length != 2 + n + 3 * q) return INVALID_RESULT;

    long[MAX_N] coordinates = {};
    for (usz i = 0; i < n; ++i) {
        long value = input[2 + i];
        if (value < -1000 || value > 1000) return INVALID_RESULT;
        coordinates[i] = value;
    }
    for (usz i = 1; i < n; ++i) {
        long value = coordinates[i];
        usz j = i;
        while (j > 0 && coordinates[j - 1] > value) {
            coordinates[j] = coordinates[j - 1];
            --j;
        }
        coordinates[j] = value;
    }
    usz distinct = 0;
    for (usz i = 0; i < n; ++i) {
        if (distinct == 0 || coordinates[i] != coordinates[distinct - 1]) {
            coordinates[distinct++] = coordinates[i];
        }
    }
    usz query_offset = 2 + n;
    for (usz qi = 0; qi < q; ++qi) {
        long left = input[query_offset + 3 * qi];
        long right = input[query_offset + 3 * qi + 1];
        long k = input[query_offset + 3 * qi + 2];
        if (left < 0 || right < left || right >= (long)n || k < 1 || k > right - left + 1) return INVALID_RESULT;
    }

    int[MAX_NODES] left_child = {};
    int[MAX_NODES] right_child = {};
    int[MAX_NODES] counts = {};
    int[MAX_N + 1] roots = {};
    usz node_count = 1;
    for (usz i = 0; i < n; ++i) {
        int rank = lower_bound_i64(&coordinates[0], distinct, input[2 + i]);
        int previous_root = roots[i];
        if (node_count >= MAX_NODES) return INVALID_RESULT;
        int new_root = (int)node_count++;
        left_child[new_root] = left_child[previous_root];
        right_child[new_root] = right_child[previous_root];
        counts[new_root] = counts[previous_root] + 1;
        int old_node = previous_root;
        int new_node = new_root;
        usz low = 0;
        usz high = distinct;
        while (high - low > 1) {
            usz middle = low + (high - low) / 2;
            int old_child = rank < (int)middle ? left_child[old_node] : right_child[old_node];
            if (node_count >= MAX_NODES) return INVALID_RESULT;
            int new_child = (int)node_count++;
            left_child[new_child] = left_child[old_child];
            right_child[new_child] = right_child[old_child];
            counts[new_child] = counts[old_child] + 1;
            if (rank < (int)middle) {
                left_child[new_node] = new_child;
                high = middle;
            } else {
                right_child[new_node] = new_child;
                low = middle;
            }
            old_node = old_child;
            new_node = new_child;
        }
        roots[i + 1] = new_root;
    }

    long checksum = 0;
    for (usz qi = 0; qi < q; ++qi) {
        usz offset = query_offset + 3 * qi;
        usz left = (usz)input[offset];
        usz right = (usz)input[offset + 1];
        int k = (int)input[offset + 2];
        int before = roots[left];
        int after = roots[right + 1];
        usz low = 0;
        usz high = distinct;
        while (high - low > 1) {
            usz middle = low + (high - low) / 2;
            int in_left = left_child[after];
            int out_left = left_child[before];
            int left_count = counts[in_left] - counts[out_left];
            if (k <= left_count) {
                before = out_left;
                after = in_left;
                high = middle;
            } else {
                k -= left_count;
                before = right_child[before];
                after = right_child[after];
                low = middle;
            }
        }
        checksum += ((long)qi + 1) * coordinates[low];
    }
    return checksum;
}
