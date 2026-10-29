module point_set_range_composite;

const long MODULUS = 998244353;
const usz MAX_N = 16;
const usz MAX_OPERATIONS = 32;
const usz MAX_INPUT_LENGTH = 162;
const usz TREE_CAPACITY = 64;

struct AffineMap { long a; long b; }

fn AffineMap identity_map() {
    return {.a = 1, .b = 0};
}

fn AffineMap compose(AffineMap left, AffineMap right) {
    return {
        .a = (right.a * left.a) % MODULUS,
        .b = (right.a * left.b + right.b) % MODULUS,
    };
}

fn long point_set_range_composite(long* values, usz length)
    @export("point_set_range_composite") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = values[0];
    long q_value = values[1];
    if (n_value < 1 || n_value > (long)MAX_N || q_value < 0 || q_value > (long)MAX_OPERATIONS) return -1;
    usz n = (usz)n_value;
    usz q = (usz)q_value;
    if (length != 2 + 2 * n + 4 * q) return -1;

    for (usz i = 0; i < n; i++) {
        long a = values[2 + 2 * i];
        long b = values[3 + 2 * i];
        if (a < 0 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;
    }

    usz base = 1;
    while (base < n) base *= 2;
    AffineMap[TREE_CAPACITY] storage;
    AffineMap* tree = &storage[0];
    for (usz i = 0; i < TREE_CAPACITY; i++) tree[i] = identity_map();
    for (usz i = 0; i < n; i++) {
        tree[base + i] = {.a = values[2 + 2 * i], .b = values[3 + 2 * i]};
    }
    for (usz node = base; node > 1; node--) {
        usz parent = node - 1;
        tree[parent] = compose(tree[2 * parent], tree[2 * parent + 1]);
    }

    long checksum = 0;
    long query_number = 0;
    usz cursor = 2 + 2 * n;
    for (usz operation = 0; operation < q; operation++) {
        long opcode = values[cursor];
        long first = values[cursor + 1];
        long second = values[cursor + 2];
        long third = values[cursor + 3];
        cursor += 4;
        if (opcode == 0) {
            if (first < 0 || first >= n_value || second < 0 || second >= MODULUS ||
                third < 0 || third >= MODULUS) return -1;
            usz node = base + (usz)first;
            tree[node] = {.a = second, .b = third};
            while (node > 1) {
                node /= 2;
                tree[node] = compose(tree[2 * node], tree[2 * node + 1]);
            }
        } else if (opcode == 1) {
            if (first < 0 || first > second || second > n_value || third < 0 || third >= MODULUS) return -1;
            usz left_index = base + (usz)first;
            usz right_index = base + (usz)second;
            AffineMap left = identity_map();
            AffineMap right = identity_map();
            while (left_index < right_index) {
                if (left_index & 1) {
                    left = compose(left, tree[left_index]);
                    left_index++;
                }
                if (right_index & 1) {
                    right_index--;
                    right = compose(tree[right_index], right);
                }
                left_index /= 2;
                right_index /= 2;
            }
            AffineMap range = compose(left, right);
            long answer = (range.a * third + range.b) % MODULUS;
            query_number++;
            checksum = (checksum + query_number * answer) % MODULUS;
        } else {
            return -1;
        }
    }
    return cursor == length ? checksum : -1;
}
