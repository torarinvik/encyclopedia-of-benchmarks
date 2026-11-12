module unionfind_with_potential_non_commutative_group;

const long MAX_N = 32;
const long MAX_Q = 64;
const long MODULUS = 998244353;

fn long normalize(long value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

fn void matrix_multiply(const long* left, const long* right, long* result) {
    long temporary[4] = {0, 0, 0, 0};
    for (usz row = 0; row < 2; row += 1)
        for (usz column = 0; column < 2; column += 1)
            for (usz inner = 0; inner < 2; inner += 1)
                temporary[2 * row + column] = normalize(temporary[2 * row + column] +
                    left[2 * row + inner] * right[2 * inner + column]);
    for (usz cell = 0; cell < 4; cell += 1) result[cell] = temporary[cell];
}

fn void matrix_inverse(const long* matrix, long* inverse) {
    long temporary[4] = {matrix[3], normalize(-matrix[1]), normalize(-matrix[2]), matrix[0]};
    for (usz cell = 0; cell < 4; cell += 1) inverse[cell] = temporary[cell];
}

fn bool matrix_equal(const long* left, const long* right) {
    for (usz cell = 0; cell < 4; cell += 1) if (left[cell] != right[cell]) return false;
    return true;
}

fn usz find_root(long* parent, long* difference, usz item) {
    if ((usz)parent[item] != item) {
        usz old_parent = (usz)parent[item];
        usz root = find_root(parent, difference, old_parent);
        long product[4];
        matrix_multiply(&difference[4 * old_parent], &difference[4 * item], product);
        for (usz cell = 0; cell < 4; cell += 1) difference[4 * item + cell] = product[cell];
        parent[item] = (long)root;
    }
    return (usz)parent[item];
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long unionfind_with_potential_non_commutative_group(long* input, usz length,
    char* output, usz capacity) @export("unionfind_with_potential_non_commutative_group") {
    if (input == null || length < 9 || length > 2 + 7 * (usz)MAX_Q) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != 2 + 7 * q) return -1;
    for (usz operation = 0; operation < q; operation += 1) {
        usz position = 2 + 7 * operation;
        long kind = input[position], u = input[position + 1], v = input[position + 2];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value) return -1;
        if (kind == 0) {
            long a = input[position + 3], b = input[position + 4];
            long c = input[position + 5], d = input[position + 6];
            if (a < 0 || a >= MODULUS || b < 0 || b >= MODULUS ||
                c < 0 || c >= MODULUS || d < 0 || d >= MODULUS || normalize(a * d - b * c) != 1) return -1;
        } else if (kind == 1) {
            for (usz cell = 0; cell < 4; cell += 1) if (input[position + 3 + cell] != 0) return -1;
        } else return -1;
    }
    usz required = 32 * q;
    if (output == null || capacity < required) return -2;

    long parent[MAX_N], set_size[MAX_N], difference[4 * MAX_N];
    for (usz item = 0; item < n; item += 1) {
        parent[item] = (long)item; set_size[item] = 1;
        difference[4 * item] = 1; difference[4 * item + 1] = 0;
        difference[4 * item + 2] = 0; difference[4 * item + 3] = 1;
    }
    for (usz operation = 0; operation < q; operation += 1) {
        usz position = 2 + 7 * operation;
        long kind = input[position];
        usz u = (usz)input[position + 1], v = (usz)input[position + 2];
        long row[4] = {0, 0, 0, 0};
        usz root_u = find_root(parent, difference, u), root_v = find_root(parent, difference, v);
        if (kind == 1) {
            if (root_u == root_v) {
                long inverse_v[4], relative[4];
                matrix_inverse(&difference[4 * v], inverse_v);
                matrix_multiply(inverse_v, &difference[4 * u], relative);
                for (usz cell = 0; cell < 4; cell += 1) row[cell] = relative[cell];
            } else for (usz cell = 0; cell < 4; cell += 1) row[cell] = -1;
        } else {
            long relation[4] = {input[position + 3], input[position + 4], input[position + 5], input[position + 6]};
            if (root_u == root_v) {
                long inverse_v[4], known[4];
                matrix_inverse(&difference[4 * v], inverse_v);
                matrix_multiply(inverse_v, &difference[4 * u], known);
                row[0] = matrix_equal(known, relation) ? 1 : 0;
            } else if (set_size[root_u] < set_size[root_v]) {
                long first[4], inverse_u[4];
                matrix_multiply(&difference[4 * v], relation, first);
                matrix_inverse(&difference[4 * u], inverse_u);
                matrix_multiply(first, inverse_u, &difference[4 * root_u]);
                parent[root_u] = (long)root_v; set_size[root_v] += set_size[root_u]; row[0] = 1;
            } else {
                long inverse_relation[4], first[4], inverse_v[4];
                matrix_inverse(relation, inverse_relation);
                matrix_multiply(&difference[4 * u], inverse_relation, first);
                matrix_inverse(&difference[4 * v], inverse_v);
                matrix_multiply(first, inverse_v, &difference[4 * root_v]);
                parent[root_v] = (long)root_u; set_size[root_u] += set_size[root_v]; row[0] = 1;
            }
        }
        for (usz cell = 0; cell < 4; cell += 1) store_i64_le(output, 32 * operation + 8 * cell, row[cell]);
    }
    return (long)required;
}
