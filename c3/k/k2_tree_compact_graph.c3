module k2_tree_compact_graph;

const usz MAX_N = 32;
const usz MAX_Q = 128;
const usz MAX_INPUT = 419;
const usz T_BYTES = 43;
const usz L_BYTES = 128;
const usz T_MAX_BITS = 340;
const usz NODE_CAP = 256;

fn u8 bit_get(u8* bits, usz index) {
    return (u8)((bits[index >> 3] >> (index & 7)) & 1);
}

fn void bit_set(u8* bits, usz index) {
    bits[index >> 3] |= (u8)(1 << (index & 7));
}

fn bool block_nonempty(long* rows, usz n, usz row_start, usz col_start, usz side) {
    ulong mask = ((1ul << side) - 1) << col_start;
    for (usz row = row_start; row < row_start + side; row++) {
        if (row < n && ((ulong)rows[row] & mask) != 0) return true;
    }
    return false;
}

fn void build_tree(long* rows, usz n, u8* t_bits, u8* l_bits,
                   ushort* rank_prefix, u8* current_rows, u8* current_cols,
                   u8* next_rows, u8* next_cols, usz* t_length,
                   usz* l_length, usz* height_out) {
    usz side = 2;
    usz height = 1;
    while (side < n) { side <<= 1; height++; }
    usz current_count = 1;
    usz current_side = side;
    usz t_used = 0;
    usz l_used = 0;
    current_rows[0] = 0;
    current_cols[0] = 0;
    for (usz level = 1; level <= height; level++) {
        usz child_side = current_side / 2;
        usz next_count = 0;
        for (usz parent = 0; parent < current_count; parent++) {
            usz parent_row = current_rows[parent];
            usz parent_col = current_cols[parent];
            for (usz quadrant = 0; quadrant < 4; quadrant++) {
                usz child_row = parent_row + (quadrant / 2) * child_side;
                usz child_col = parent_col + (quadrant % 2) * child_side;
                bool occupied = block_nonempty(rows, n, child_row, child_col, child_side);
                if (level < height) {
                    if (occupied) {
                        bit_set(t_bits, t_used);
                        next_rows[next_count] = (u8)child_row;
                        next_cols[next_count] = (u8)child_col;
                        next_count++;
                    }
                    t_used++;
                } else {
                    if (occupied) bit_set(l_bits, l_used);
                    l_used++;
                }
            }
        }
        if (level < height) {
            for (usz i = 0; i < next_count; i++) {
                current_rows[i] = next_rows[i];
                current_cols[i] = next_cols[i];
            }
            current_count = next_count;
            current_side = child_side;
        }
    }
    rank_prefix[0] = 0;
    for (usz i = 0; i < t_used; i++)
        rank_prefix[i + 1] = (ushort)(rank_prefix[i] + bit_get(t_bits, i));
    *t_length = t_used;
    *l_length = l_used;
    *height_out = height;
}

fn bool edge_query(u8* t_bits, u8* l_bits, usz t_length,
                   ushort* rank_prefix, usz height, usz u, usz v) {
    long parent = -1;
    usz row_start = 0;
    usz col_start = 0;
    usz side = 1 << height;
    for (usz depth = 0; depth < height; depth++) {
        usz child_side = side / 2;
        usz row_bit = 0;
        usz col_bit = 0;
        if (u >= row_start + child_side) row_bit = 1;
        if (v >= col_start + child_side) col_bit = 1;
        usz quadrant = 2 * row_bit + col_bit;
        usz child_base = parent < 0 ? 0 : 4 * rank_prefix[(usz)parent + 1];
        usz child = child_base + quadrant;
        if (row_bit != 0) row_start += child_side;
        if (col_bit != 0) col_start += child_side;
        if (child < t_length) {
            if (bit_get(t_bits, child) == 0) return false;
            parent = (long)child;
        } else {
            return bit_get(l_bits, child - t_length) != 0;
        }
        side = child_side;
    }
    return false;
}

fn void put_i64_le(char* output, usz offset, ulong value) {
    for (usz byte = 0; byte < 8; byte++)
        output[offset + byte] = (char)(value >> (8 * byte));
}

fn long k2_tree_compact_graph(long* input, usz length, char* output,
                              usz capacity) @export("k2_tree_compact_graph") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N || length < (usz)n_value + 2) return -1;
    usz n = (usz)n_value;
    ulong row_limit = (1ul << n) - 1;
    for (usz row = 0; row < n; row++)
        if (input[1 + row] < 0 || (ulong)input[1 + row] > row_limit) return -1;
    usz q_index = n + 1;
    long q_value = input[q_index];
    if (q_value < 0 || q_value > (long)MAX_Q) return -1;
    usz q = (usz)q_value;
    if (length != n + 2 + 3 * q) return -1;
    usz query_start = n + 2;
    for (usz j = 0; j < q; j++) {
        long op = input[query_start + 3 * j];
        long u = input[query_start + 3 * j + 1];
        long v = input[query_start + 3 * j + 2];
        if (u < 0 || (ulong)u >= n) return -1;
        if (op == 0) {
            if (v < 0 || (ulong)v >= n) return -1;
        } else if (op == 1) {
            if (v != 0) return -1;
        } else return -1;
    }
    usz output_bytes = 8 * (q + 1);
    if (output == null || capacity < output_bytes) return -2;

    u8[T_BYTES] t_bits = {};
    u8[L_BYTES] l_bits = {};
    ushort[T_MAX_BITS + 1] rank_prefix = {};
    u8[NODE_CAP] current_rows = {};
    u8[NODE_CAP] current_cols = {};
    u8[NODE_CAP] next_rows = {};
    u8[NODE_CAP] next_cols = {};
    usz t_length = 0;
    usz l_length = 0;
    usz height = 0;
    build_tree(input + 1, n, &t_bits[0], &l_bits[0], &rank_prefix[0],
               &current_rows[0], &current_cols[0], &next_rows[0], &next_cols[0],
               &t_length, &l_length, &height);
    (void)l_length;
    put_i64_le(output, 0, (ulong)q);
    for (usz j = 0; j < q; j++) {
        long op = input[query_start + 3 * j];
        usz u = (usz)input[query_start + 3 * j + 1];
        usz v = (usz)input[query_start + 3 * j + 2];
        ulong result = 0;
        if (op == 0) {
            result = (ulong)edge_query(&t_bits[0], &l_bits[0], t_length,
                                       &rank_prefix[0], height, u, v);
        } else {
            for (usz successor = 0; successor < n; successor++)
                if (edge_query(&t_bits[0], &l_bits[0], t_length,
                               &rank_prefix[0], height, u, successor))
                    result |= 1ul << successor;
        }
        put_i64_le(output, 8 * (j + 1), result);
    }
    return (long)output_bytes;
}
