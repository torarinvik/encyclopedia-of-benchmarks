package k2_tree_compact_graph

import "core:c"

MAX_N :: 32
MAX_Q :: 128
MAX_INPUT :: 419
T_BYTES :: 43
L_BYTES :: 128
T_MAX_BITS :: 340
NODE_CAP :: 256

bit_get :: proc(bits: [^]u8, index: int) -> u8 {
    return (bits[index / 8] >> (index % 8)) & 1
}

bit_set :: proc(bits: [^]u8, index: int) {
    bits[index / 8] |= 1 << (index % 8)
}

block_nonempty :: proc(rows: [^]i64, row_offset, n, row_start, col_start, side: int) -> bool {
    mask := ((u64(1) << side) - 1) << col_start
    for row := row_start; row < row_start + side; row += 1 {
        if row < n && (u64(rows[row_offset+row]) & mask) != 0 do return true
    }
    return false
}

build_tree :: proc(rows: [^]i64, row_offset, n: int,
    t_bits, l_bits: [^]u8, rank_prefix: [^]u16,
    current_rows, current_cols, next_rows, next_cols: [^]u8) -> (t_len, l_len, height: int) {
    side, height := 2, 1
    for side < n { side *= 2; height += 1 }
    current_count, current_side := 1, side
    t_len, l_len := 0, 0
    current_rows[0], current_cols[0] = 0, 0
    for level := 1; level <= height; level += 1 {
        child_side := current_side / 2
        next_count := 0
        for parent := 0; parent < current_count; parent += 1 {
            parent_row, parent_col := int(current_rows[parent]), int(current_cols[parent])
            for quadrant := 0; quadrant < 4; quadrant += 1 {
                child_row := parent_row + (quadrant / 2) * child_side
                child_col := parent_col + (quadrant % 2) * child_side
                occupied := block_nonempty(rows, row_offset, n, child_row, child_col, child_side)
                if level < height {
                    if occupied {
                        bit_set(t_bits, t_len)
                        next_rows[next_count], next_cols[next_count] = u8(child_row), u8(child_col)
                        next_count += 1
                    }
                    t_len += 1
                } else {
                    if occupied do bit_set(l_bits, l_len)
                    l_len += 1
                }
            }
        }
        if level < height {
            for i := 0; i < next_count; i += 1 {
                current_rows[i], current_cols[i] = next_rows[i], next_cols[i]
            }
            current_count, current_side = next_count, child_side
        }
    }
    rank_prefix[0] = 0
    for i := 0; i < t_len; i += 1 {
        rank_prefix[i+1] = rank_prefix[i] + u16(bit_get(t_bits, i))
    }
    return t_len, l_len, height
}

edge_query :: proc(t_bits, l_bits: [^]u8, t_len: int,
    rank_prefix: [^]u16, height, u, v: int) -> bool {
    parent := -1
    row_start, col_start := 0, 0
    side := 1 << height
    for depth := 0; depth < height; depth += 1 {
        child_side := side / 2
        row_bit, col_bit := 0, 0
        if u >= row_start + child_side do row_bit = 1
        if v >= col_start + child_side do col_bit = 1
        quadrant := 2*row_bit + col_bit
        child_base := 0
        if parent >= 0 do child_base = 4 * int(rank_prefix[parent+1])
        child := child_base + quadrant
        if row_bit != 0 do row_start += child_side
        if col_bit != 0 do col_start += child_side
        if child < t_len {
            if bit_get(t_bits, child) == 0 do return false
            parent = child
        } else {
            return bit_get(l_bits, child-t_len) != 0
        }
        side = child_side
    }
    return false
}

put_i64_le :: proc(output: [^]u8, offset: int, value: u64) {
    bits := value
    for byte := 0; byte < 8; byte += 1 {
        output[offset+byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
k2_tree_compact_graph :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n_value := input[0]
    if n_value < 1 || n_value > MAX_N || length < c.size_t(n_value+2) do return -1
    n := int(n_value)
    row_limit := (u64(1) << n) - 1
    for row := 0; row < n; row += 1 {
        if input[1+row] < 0 || u64(input[1+row]) > row_limit do return -1
    }
    q_index := n + 1
    q_value := input[q_index]
    if q_value < 0 || q_value > MAX_Q do return -1
    q := int(q_value)
    if length != c.size_t(n+2+3*q) do return -1
    query_start := n + 2
    for j := 0; j < q; j += 1 {
        op, u, v := input[query_start+3*j], input[query_start+3*j+1], input[query_start+3*j+2]
        if u < 0 || u >= n_value do return -1
        if op == 0 {
            if v < 0 || v >= n_value do return -1
        } else if op == 1 {
            if v != 0 do return -1
        } else do return -1
    }
    output_bytes := 8 * (q + 1)
    if output == nil || capacity < c.size_t(output_bytes) do return -2

    t_bits: [T_BYTES]u8 = {}
    l_bits: [L_BYTES]u8 = {}
    rank_prefix: [T_MAX_BITS+1]u16 = {}
    current_rows, current_cols, next_rows, next_cols: [NODE_CAP]u8 = {}
    t_len, l_len, height := build_tree(input, 1, n, &t_bits[0], &l_bits[0],
        &rank_prefix[0], &current_rows[0], &current_cols[0], &next_rows[0], &next_cols[0])
    _ = l_len
    put_i64_le(output, 0, u64(q))
    for j := 0; j < q; j += 1 {
        op := input[query_start+3*j]
        u, v := int(input[query_start+3*j+1]), int(input[query_start+3*j+2])
        result: u64 = 0
        if op == 0 {
            if edge_query(&t_bits[0], &l_bits[0], t_len, &rank_prefix[0], height, u, v) do result = 1
        } else {
            for successor := 0; successor < n; successor += 1 {
                if edge_query(&t_bits[0], &l_bits[0], t_len, &rank_prefix[0], height, u, successor) {
                    result |= u64(1) << successor
                }
            }
        }
        put_i64_le(output, 8*(j+1), result)
    }
    return i64(output_bytes)
}
