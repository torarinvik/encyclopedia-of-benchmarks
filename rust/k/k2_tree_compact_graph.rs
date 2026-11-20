//! Clean-room bounded packed k²-tree graph query profile.

use std::slice;

const MAX_N: usize = 32;
const MAX_Q: usize = 128;
const MAX_INPUT: usize = 419;
const T_BYTES: usize = 43;
const L_BYTES: usize = 128;
const T_MAX_BITS: usize = 340;
const NODE_CAP: usize = 256;

fn bit_get(bits: &[u8], index: usize) -> u8 { (bits[index >> 3] >> (index & 7)) & 1 }
fn bit_set(bits: &mut [u8], index: usize) { bits[index >> 3] |= 1 << (index & 7); }

fn block_nonempty(rows: &[i64], row_start: usize, col_start: usize, side: usize) -> bool {
    let mask = ((1_u64 << side) - 1) << col_start;
    for row in row_start..row_start + side {
        if row < rows.len() && ((rows[row] as u64) & mask) != 0 { return true; }
    }
    false
}

fn build_tree(rows: &[i64], t_bits: &mut [u8; T_BYTES], l_bits: &mut [u8; L_BYTES],
    rank_prefix: &mut [u16; T_MAX_BITS + 1], current_rows: &mut [u8; NODE_CAP],
    current_cols: &mut [u8; NODE_CAP], next_rows: &mut [u8; NODE_CAP],
    next_cols: &mut [u8; NODE_CAP]) -> (usize, usize, usize) {
    let mut side = 2;
    let mut height = 1;
    while side < rows.len() { side <<= 1; height += 1; }
    let (mut current_count, mut current_side) = (1, side);
    let (mut t_len, mut l_len) = (0, 0);
    current_rows[0] = 0;
    current_cols[0] = 0;
    for level in 1..=height {
        let child_side = current_side / 2;
        let mut next_count = 0;
        for parent in 0..current_count {
            let parent_row = current_rows[parent] as usize;
            let parent_col = current_cols[parent] as usize;
            for quadrant in 0..4 {
                let child_row = parent_row + (quadrant / 2) * child_side;
                let child_col = parent_col + (quadrant % 2) * child_side;
                let occupied = block_nonempty(rows, child_row, child_col, child_side);
                if level < height {
                    if occupied {
                        bit_set(t_bits, t_len);
                        next_rows[next_count] = child_row as u8;
                        next_cols[next_count] = child_col as u8;
                        next_count += 1;
                    }
                    t_len += 1;
                } else {
                    if occupied { bit_set(l_bits, l_len); }
                    l_len += 1;
                }
            }
        }
        if level < height {
            current_rows[..next_count].copy_from_slice(&next_rows[..next_count]);
            current_cols[..next_count].copy_from_slice(&next_cols[..next_count]);
            current_count = next_count;
            current_side = child_side;
        }
    }
    rank_prefix[0] = 0;
    for i in 0..t_len {
        rank_prefix[i + 1] = rank_prefix[i] + u16::from(bit_get(t_bits, i));
    }
    (t_len, l_len, height)
}

fn edge_query(t_bits: &[u8; T_BYTES], l_bits: &[u8; L_BYTES], t_len: usize,
    rank_prefix: &[u16; T_MAX_BITS + 1], height: usize, u: usize, v: usize) -> bool {
    let mut parent: i64 = -1;
    let (mut row_start, mut col_start) = (0, 0);
    let mut side = 1_usize << height;
    for _ in 0..height {
        let child_side = side / 2;
        let row_bit = usize::from(u >= row_start + child_side);
        let col_bit = usize::from(v >= col_start + child_side);
        let quadrant = 2 * row_bit + col_bit;
        let child_base = if parent < 0 { 0 } else { 4 * rank_prefix[parent as usize + 1] as usize };
        let child = child_base + quadrant;
        if row_bit != 0 { row_start += child_side; }
        if col_bit != 0 { col_start += child_side; }
        if child < t_len {
            if bit_get(t_bits, child) == 0 { return false; }
            parent = child as i64;
        } else {
            return bit_get(l_bits, child - t_len) != 0;
        }
        side = child_side;
    }
    false
}

unsafe fn put_i64_le(output: *mut u8, offset: usize, value: u64) {
    for byte in 0..8 { output.add(offset + byte).write((value >> (byte * 8)) as u8); }
}

#[no_mangle]
pub unsafe extern "C" fn k2_tree_compact_graph(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = slice::from_raw_parts(input, length);
    let n_value = values[0];
    if n_value < 1 || n_value > MAX_N as i64 || length < n_value as usize + 2 { return -1; }
    let n = n_value as usize;
    let row_limit = (1_u64 << n) - 1;
    let rows = &values[1..1 + n];
    if rows.iter().any(|&mask| mask < 0 || mask as u64 > row_limit) { return -1; }
    let q_value = values[n + 1];
    if q_value < 0 || q_value > MAX_Q as i64 { return -1; }
    let q = q_value as usize;
    if length != n + 2 + 3 * q { return -1; }
    let query_start = n + 2;
    for j in 0..q {
        let op = values[query_start + 3 * j];
        let u = values[query_start + 3 * j + 1];
        let v = values[query_start + 3 * j + 2];
        if u < 0 || u as usize >= n { return -1; }
        if op == 0 {
            if v < 0 || v as usize >= n { return -1; }
        } else if op == 1 {
            if v != 0 { return -1; }
        } else { return -1; }
    }
    let output_bytes = 8 * (q + 1);
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut t_bits = [0_u8; T_BYTES];
    let mut l_bits = [0_u8; L_BYTES];
    let mut rank_prefix = [0_u16; T_MAX_BITS + 1];
    let mut current_rows = [0_u8; NODE_CAP];
    let mut current_cols = [0_u8; NODE_CAP];
    let mut next_rows = [0_u8; NODE_CAP];
    let mut next_cols = [0_u8; NODE_CAP];
    let (t_len, _l_len, height) = build_tree(rows, &mut t_bits, &mut l_bits,
        &mut rank_prefix, &mut current_rows, &mut current_cols, &mut next_rows, &mut next_cols);

    put_i64_le(output, 0, q as u64);
    for j in 0..q {
        let op = values[query_start + 3 * j];
        let u = values[query_start + 3 * j + 1] as usize;
        let v = values[query_start + 3 * j + 2] as usize;
        let mut result = 0_u64;
        if op == 0 {
            result = u64::from(edge_query(&t_bits, &l_bits, t_len, &rank_prefix, height, u, v));
        } else {
            for successor in 0..n {
                if edge_query(&t_bits, &l_bits, t_len, &rank_prefix, height, u, successor) {
                    result |= 1_u64 << successor;
                }
            }
        }
        put_i64_le(output, 8 * (j + 1), result);
    }
    output_bytes as i64
}
