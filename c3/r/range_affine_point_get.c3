module range_affine_point_get;

const int MAX_N = 256;
const int MAX_Q = 256;
const int MAX_BASE = 256;
const int MAX_TREE = 2 * MAX_BASE;
const usz MAX_PARSEABLE_INPUT = 2 + (usz)MAX_N + 5 * (usz)MAX_Q + 1;
const long MOD = 998244353;

struct Operation { long kind, left, right, multiplier, offset; }

fn void apply_tag(long* mul, long* add, usz node, long multiplier, long offset) {
    add[node] = (multiplier * add[node] + offset) % MOD;
    mul[node] = (multiplier * mul[node]) % MOD;
}

fn void push(long* mul, long* add, usz node) {
    if (mul[node] != 1 || add[node] != 0) {
        long multiplier = mul[node], offset = add[node];
        apply_tag(mul, add, 2 * node, multiplier, offset);
        apply_tag(mul, add, 2 * node + 1, multiplier, offset);
        mul[node] = 1;
        add[node] = 0;
    }
}

fn void range_apply(long* mul, long* add, usz node, usz segment_left, usz segment_right,
                    usz left, usz right, long multiplier, long offset) {
    if (right <= segment_left || segment_right <= left) return;
    if (left <= segment_left && segment_right <= right) {
        apply_tag(mul, add, node, multiplier, offset);
        return;
    }
    push(mul, add, node);
    usz middle = segment_left + (segment_right - segment_left) / 2;
    range_apply(mul, add, 2 * node, segment_left, middle, left, right, multiplier, offset);
    range_apply(mul, add, 2 * node + 1, middle, segment_right, left, right, multiplier, offset);
}

fn long point_get(long* mul, long* add, long* initial, usz node,
                  usz segment_left, usz segment_right, usz index) {
    if (segment_right - segment_left == 1)
        return (mul[node] * initial[index] + add[node]) % MOD;
    push(mul, add, node);
    usz middle = segment_left + (segment_right - segment_left) / 2;
    if (index < middle)
        return point_get(mul, add, initial, 2 * node, segment_left, middle, index);
    return point_get(mul, add, initial, 2 * node + 1, middle, segment_right, index);
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long range_affine_point_get(long* input, usz length, char* output, usz capacity)
    @export("range_affine_point_get") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (2 + n > length) return -1;
    long[MAX_N] initial;
    Operation[MAX_Q] operations;
    for (usz index = 0; index < n; index++) {
        initial[index] = input[2 + index];
        if (initial[index] < 0 || initial[index] >= MOD) return -1;
    }
    usz cursor = 2 + n, query_count = 0;
    for (usz index = 0; index < q; index++) {
        if (cursor >= length) return -1;
        long kind = input[cursor++];
        if (kind == 0) {
            if (cursor + 4 > length) return -1;
            long left = input[cursor], right = input[cursor + 1];
            long multiplier = input[cursor + 2], offset = input[cursor + 3];
            cursor += 4;
            if (left < 0 || left >= right || right > n_value ||
                multiplier < 1 || multiplier >= MOD || offset < 0 || offset >= MOD) return -1;
            operations[index] = {kind, left, right, multiplier, offset};
        } else if (kind == 1) {
            if (cursor >= length) return -1;
            long point = input[cursor++];
            if (point < 0 || point >= n_value) return -1;
            operations[index] = {kind, point, 0, 0, 0};
            query_count++;
        } else return -1;
    }
    if (cursor != length) return -1;
    usz output_bytes = 8 * query_count;
    if (output_bytes > 0 && (output == null || capacity < output_bytes)) return -2;

    usz base = 1;
    while (base < n) base *= 2;
    long[MAX_TREE] mul, add;
    for (usz node = 0; node < MAX_TREE; node++) { mul[node] = 1; add[node] = 0; }
    usz answer = 0;
    for (usz index = 0; index < q; index++) {
        Operation operation = operations[index];
        if (operation.kind == 0) {
            range_apply(&mul[0], &add[0], 1, 0, base, (usz)operation.left,
                        (usz)operation.right, operation.multiplier, operation.offset);
        } else {
            long value = point_get(&mul[0], &add[0], &initial[0], 1, 0, base, (usz)operation.left);
            store_i64_le(output, 8 * answer++, value);
        }
    }
    return (long)output_bytes;
}
