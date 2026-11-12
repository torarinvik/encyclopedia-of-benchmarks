module range_affine_range_sum;

const usz MAX_LENGTH = 64;
const usz MAX_OPERATIONS = 64;
const usz MAX_TREE_NODES = 256;
const usz MAX_PARSEABLE_INPUT_VALUES = 387;
const long MODULUS = 998244353;

fn long reduce(long value) { return value % MODULUS; }

fn void apply_node(long* sum, long* lazy_mul, long* lazy_add, usz node,
                   usz segment_length, long a, long b) {
    sum[node] = reduce(a * sum[node] + b * (long)segment_length);
    lazy_mul[node] = reduce(a * lazy_mul[node]);
    lazy_add[node] = reduce(a * lazy_add[node] + b);
}

fn void push(long* sum, long* lazy_mul, long* lazy_add, usz node, usz left, usz right) {
    if (right - left <= 1 || (lazy_mul[node] == 1 && lazy_add[node] == 0)) return;
    usz middle = left + (right - left) / 2;
    apply_node(sum, lazy_mul, lazy_add, node * 2, middle - left, lazy_mul[node], lazy_add[node]);
    apply_node(sum, lazy_mul, lazy_add, node * 2 + 1, right - middle, lazy_mul[node], lazy_add[node]);
    lazy_mul[node] = 1;
    lazy_add[node] = 0;
}

fn void build(long* sum, long* values, usz node, usz left, usz right) {
    if (right - left == 1) { sum[node] = values[left]; return; }
    usz middle = left + (right - left) / 2;
    build(sum, values, node * 2, left, middle);
    build(sum, values, node * 2 + 1, middle, right);
    sum[node] = reduce(sum[node * 2] + sum[node * 2 + 1]);
}

fn void update(long* sum, long* lazy_mul, long* lazy_add, usz ql, usz qr,
               usz node, usz left, usz right, long a, long b) {
    if (ql <= left && right <= qr) { apply_node(sum, lazy_mul, lazy_add, node, right - left, a, b); return; }
    if (qr <= left || right <= ql) return;
    push(sum, lazy_mul, lazy_add, node, left, right);
    usz middle = left + (right - left) / 2;
    update(sum, lazy_mul, lazy_add, ql, qr, node * 2, left, middle, a, b);
    update(sum, lazy_mul, lazy_add, ql, qr, node * 2 + 1, middle, right, a, b);
    sum[node] = reduce(sum[node * 2] + sum[node * 2 + 1]);
}

fn long query(long* sum, long* lazy_mul, long* lazy_add, usz ql, usz qr,
              usz node, usz left, usz right) {
    if (ql <= left && right <= qr) return sum[node];
    if (qr <= left || right <= ql) return 0;
    push(sum, lazy_mul, lazy_add, node, left, right);
    usz middle = left + (right - left) / 2;
    return reduce(query(sum, lazy_mul, lazy_add, ql, qr, node * 2, left, middle) +
                  query(sum, lazy_mul, lazy_add, ql, qr, node * 2 + 1, middle, right));
}

fn long range_affine_range_sum_benchmark(long* input, usz length) @export("range_affine_range_sum_benchmark") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_LENGTH) return -1;
    usz n = (usz)input[0];
    if (length < n + 2) return -1;
    long[MAX_LENGTH] values;
    for (usz i = 0; i < n; i++) {
        if (input[i + 1] < 0 || input[i + 1] >= MODULUS) return -1;
        values[i] = input[i + 1];
    }
    if (input[n + 1] < 1 || input[n + 1] > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)input[n + 1];
    long[MAX_TREE_NODES] sum = zeroed;
    long[MAX_TREE_NODES] lazy_mul;
    long[MAX_TREE_NODES] lazy_add = zeroed;
    for (usz i = 0; i < MAX_TREE_NODES; i++) lazy_mul[i] = 1;
    build(&sum[0], &values[0], 1, 0, n);

    usz cursor = n + 2;
    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        if (cursor >= length) return -1;
        long opcode = input[cursor++];
        if (opcode == 0) {
            if (cursor + 4 > length) return -1;
            long left = input[cursor++]; long right = input[cursor++];
            long a = input[cursor++]; long b = input[cursor++];
            if (left < 0 || left >= right || right > (long)n || a < 1 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;
            update(&sum[0], &lazy_mul[0], &lazy_add[0], (usz)left, (usz)right, 1, 0, n, a, b);
        } else if (opcode == 1) {
            if (cursor + 2 > length) return -1;
            long left = input[cursor++]; long right = input[cursor++];
            if (left < 0 || left >= right || right > (long)n) return -1;
            long result = query(&sum[0], &lazy_mul[0], &lazy_add[0], (usz)left, (usz)right, 1, 0, n);
            checksum += (long)(operation + 1) * (result + MODULUS);
        } else return -1;
    }
    return cursor == length ? checksum : -1;
}
