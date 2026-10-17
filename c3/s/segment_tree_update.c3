module segment_tree_update;

const usz MAX_N = 64;
const usz MAX_OPERATIONS = 64;
const usz MAX_INPUT_LENGTH = 259;
const usz MAX_TREE_LENGTH = 128;
const long VALUE_MIN = -1000000;
const long VALUE_MAX = 1000000;
const ulong FNV_OFFSET = 14695981039346656037;
const ulong FNV_PRIME = 1099511628211;

fn i32 query_sum(i32* tree, usz node, usz segment_left, usz segment_right,
                 usz query_left, usz query_right) {
    if (query_left <= segment_left && segment_right <= query_right) return tree[node];
    if (query_right < segment_left || segment_right < query_left) return 0;
    usz middle = segment_left + (segment_right - segment_left) / 2;
    return query_sum(tree, node * 2, segment_left, middle, query_left, query_right)
         + query_sum(tree, node * 2 + 1, middle + 1, segment_right, query_left, query_right);
}

fn ulong hash_i64_word(ulong hash, long word) {
    ulong bits = (ulong)word;
    for (usz shift = 0; shift < 64; shift += 8)
        hash = (hash ^ (ulong)(uint8)(bits >> shift)) * FNV_PRIME;
    return hash;
}

fn long segment_tree_update_benchmark(long* input, usz length) @export("segment_tree_update_benchmark") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length < n + 2) return -1;
    if (input[n + 1] < 1 || input[n + 1] > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)input[n + 1];
    if (length != n + 2 + 3 * operation_count) return -1;

    for (usz index = 0; index < n; index++)
        if (input[index + 1] < VALUE_MIN || input[index + 1] > VALUE_MAX) return -1;
    usz operations_start = n + 2;
    usz query_count = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        usz offset = operations_start + 3 * operation;
        long type = input[offset], first = input[offset + 1], second = input[offset + 2];
        if (type == 0) {
            if (first < 0 || first > second || second >= (long)n) return -1;
            query_count++;
        } else if (type == 1) {
            if (first < 0 || first >= (long)n || second < VALUE_MIN || second > VALUE_MAX) return -1;
        } else return -1;
    }
    if (query_count == 0) return -1;

    usz power = 1;
    while (power < n) power *= 2;
    i32[MAX_TREE_LENGTH] tree = {0};
    for (usz index = 0; index < n; index++) tree[power + index] = (i32)input[index + 1];
    for (usz node = power - 1; node > 0; node--) tree[node] = tree[node * 2] + tree[node * 2 + 1];

    ulong hash = hash_i64_word(FNV_OFFSET, (long)query_count);
    for (usz operation = 0; operation < operation_count; operation++) {
        usz offset = operations_start + 3 * operation;
        long type = input[offset], first = input[offset + 1], second = input[offset + 2];
        if (type == 0) {
            i32 sum = query_sum(&tree[0], 1, 1, power, (usz)first + 1, (usz)second + 1);
            hash = hash_i64_word(hash, (long)sum);
        } else {
            usz node = power + (usz)first;
            tree[node] = (i32)second;
            while (node > 1) {
                node /= 2;
                tree[node] = tree[node * 2] + tree[node * 2 + 1];
            }
        }
    }
    return (long)(hash & 0x7fffffffffffffff);
}
