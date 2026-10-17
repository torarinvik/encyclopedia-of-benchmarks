module merge_find_set;

const long MAX_N = 256;
const long MAX_MERGES = 512;
const usz MAX_PARSEABLE_INPUT_LENGTH = 1028;

fn long merge_find_set(long* input, usz length) @export("merge_find_set") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_MERGES) return -1;
    long n = input[0];
    long merge_count = input[1];
    if (length != (usz)(2 * merge_count + 3)) return -1;

    long[256] parent = {0};
    long[256] ranks = {0};
    for (long element = 0; element < n; ++element) parent[element] = element;
    for (long operation = 0; operation < merge_count; ++operation) {
        usz position = (usz)(2 + 2 * operation);
        long first = input[position];
        long second = input[position + 1];
        if (first < 0 || second < 0 || first >= n || second >= n) return -1;
        long first_root = first;
        long second_root = second;
        while (parent[first_root] != first_root) first_root = parent[first_root];
        while (parent[second_root] != second_root) second_root = parent[second_root];
        if (first_root == second_root) continue;
        if (ranks[first_root] < ranks[second_root]) {
            parent[first_root] = second_root;
        } else if (ranks[first_root] > ranks[second_root]) {
            parent[second_root] = first_root;
        } else {
            parent[first_root] = second_root;
            ranks[second_root] += 1;
        }
    }
    long query = input[length - 1];
    if (query < 0 || query >= n) return -1;
    while (parent[query] != query) query = parent[query];
    return query;
}
