module range_parallel_unionfind;

const usz MAX_N = 64;
const usz MAX_Q = 64;
const usz MAX_LEVELS = 6;
const long MODULUS = 998244353;

fn long normalize(long value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

fn usz find_root(usz[MAX_LEVELS][MAX_N]* parent, usz level, usz item) {
    if ((*parent)[level][item] != item)
        (*parent)[level][item] = find_root(parent, level, (*parent)[level][item]);
    return (*parent)[level][item];
}

fn void merge_inner(usz level, usz left, usz right,
    usz[MAX_LEVELS][MAX_N]* parent, usz[MAX_LEVELS][MAX_N]* set_size,
    long[MAX_N]* weight, long* pair_sum) {
    usz root_left = find_root(parent, level, left);
    usz root_right = find_root(parent, level, right);
    if (root_left == root_right) return;
    if ((*set_size)[level][root_left] < (*set_size)[level][root_right]) {
        usz temporary = root_left;
        root_left = root_right;
        root_right = temporary;
    }
    (*parent)[level][root_right] = root_left;
    (*set_size)[level][root_left] += (*set_size)[level][root_right];
    if (level == 0) {
        *pair_sum = normalize(*pair_sum + (*weight)[root_left] * (*weight)[root_right]);
        (*weight)[root_left] = normalize((*weight)[root_left] + (*weight)[root_right]);
        return;
    }
    usz half = (usz)1 << (level - 1);
    merge_inner(level - 1, left, right, parent, set_size, weight, pair_sum);
    merge_inner(level - 1, left + half, right + half, parent, set_size, weight, pair_sum);
}

fn usz floor_log2(usz value) {
    usz level = 0;
    while (value > 1) { value >>= 1; level += 1; }
    return level;
}

fn void merge_ranges(usz length, usz left, usz right,
    usz[MAX_LEVELS][MAX_N]* parent, usz[MAX_LEVELS][MAX_N]* set_size,
    long[MAX_N]* weight, long* pair_sum) {
    if (length == 0) return;
    usz level = floor_log2(length - 1);
    usz block = (usz)1 << level;
    merge_inner(level, left, right, parent, set_size, weight, pair_sum);
    merge_inner(level, left + length - block, right + length - block,
                parent, set_size, weight, pair_sum);
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long range_parallel_unionfind(long* input, usz length, char* output, usz capacity)
    @export("range_parallel_unionfind") {
    if (input == null || length < 6 || length > 2 + MAX_N + 3 * MAX_Q) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || q_value < 1 || q_value > (long)MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != 2 + n + 3 * q) return -1;
    for (usz item = 0; item < n; item += 1)
        if (input[2 + item] < 0 || input[2 + item] >= MODULUS) return -1;
    usz operations_at = 2 + n;
    for (usz operation = 0; operation < q; operation += 1) {
        usz position = operations_at + 3 * operation;
        long span = input[position], left = input[position + 1], right = input[position + 2];
        if (span < 0 || span > n_value || left < 0 || right < 0 ||
            left > n_value - span || right > n_value - span) return -1;
    }
    usz required = 8 * q;
    if (output == null || capacity < required) return -2;

    usz[MAX_LEVELS][MAX_N] parent = zeroed;
    usz[MAX_LEVELS][MAX_N] set_size = zeroed;
    long[MAX_N] weight = zeroed;
    for (usz level = 0; level < MAX_LEVELS; level += 1) {
        usz block = (usz)1 << level;
        if (block > n) break;
        for (usz start = 0; start <= n - block; start += 1) {
            parent[level][start] = start;
            set_size[level][start] = 1;
        }
    }
    for (usz item = 0; item < n; item += 1) weight[item] = input[2 + item];
    long pair_sum = 0;
    for (usz operation = 0; operation < q; operation += 1) {
        usz position = operations_at + 3 * operation;
        merge_ranges((usz)input[position], (usz)input[position + 1], (usz)input[position + 2],
                     &parent, &set_size, &weight, &pair_sum);
        store_i64_le(output, 8 * operation, pair_sum);
    }
    return (long)required;
}
