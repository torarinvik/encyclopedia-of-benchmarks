const MAX_M: usize = 32;
const MAX_N: usize = 32;
const MAX_Q: usize = 64;
const STRIDE: usize = MAX_N + 1;
const MAX_INPUT: usize = 3 + MAX_M + MAX_N + 3 * MAX_Q;

#[derive(Clone, Copy, Default)]
struct Query { a: usize, b: usize, c: usize }

fn lowbit(value: usize) -> usize { value & value.wrapping_neg() }

fn fenwick_add(tree: &mut [i32; STRIDE + 1], position: usize, count: usize) {
    let mut index = position + 1;
    while index <= count {
        tree[index] += 1;
        index += lowbit(index);
    }
}

fn fenwick_prefix(tree: &[i32; STRIDE + 1], exclusive: usize) -> i32 {
    let mut total = 0;
    let mut index = exclusive;
    while index > 0 {
        total += tree[index];
        index -= lowbit(index);
    }
    total
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    for (byte, part) in value.to_le_bytes().iter().enumerate() {
        *output.add(offset + byte) = *part;
    }
}

#[no_mangle]
pub unsafe extern "C" fn prefix_substring_lcs(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let packed = std::slice::from_raw_parts(input, length);
    let (m_raw, n_raw, q_raw) = (packed[0], packed[1], packed[2]);
    if !(1..=MAX_M as i64).contains(&m_raw)
        || !(1..=MAX_N as i64).contains(&n_raw)
        || !(1..=MAX_Q as i64).contains(&q_raw) { return -1; }
    let (m, n, q) = (m_raw as usize, n_raw as usize, q_raw as usize);
    if length != 3 + m + n + 3 * q { return -1; }

    let mut s = [0i32; MAX_M];
    let mut t = [0i32; MAX_N];
    let mut offset = 3;
    for i in 0..m {
        if !(97..=122).contains(&packed[offset]) { return -1; }
        s[i] = packed[offset] as i32;
        offset += 1;
    }
    for j in 0..n {
        if !(97..=122).contains(&packed[offset]) { return -1; }
        t[j] = packed[offset] as i32;
        offset += 1;
    }
    let mut queries = [Query::default(); MAX_Q];
    let mut query_head = [-1i32; STRIDE * STRIDE];
    let mut query_next = [0i32; MAX_Q];
    for index in 0..q {
        let (a, b, c) = (packed[offset], packed[offset + 1], packed[offset + 2]);
        if a < 0 || a > m_raw || b < 0 || b > c || c > n_raw { return -1; }
        queries[index] = Query { a: a as usize, b: b as usize, c: c as usize };
        let key = queries[index].a * STRIDE + queries[index].b;
        query_next[index] = query_head[key];
        query_head[key] = index as i32;
        offset += 3;
    }
    let output_bytes = 8 * q;
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut horizontal = [[0i32; STRIDE]; STRIDE];
    let mut vertical = [[0i32; STRIDE]; STRIDE];
    for j in 0..=n { horizontal[0][j] = j as i32; }
    for i in 1..=m {
        for j in 1..=n {
            let above = horizontal[i - 1][j];
            let left = vertical[i][j - 1];
            if s[i - 1] == t[j - 1] {
                horizontal[i][j] = left;
                vertical[i][j] = above;
            } else {
                horizontal[i][j] = above.max(left);
                vertical[i][j] = above.min(left);
            }
        }
    }

    let mut answers = [0i32; MAX_Q];
    for a in 0..=m {
        let mut value_head = [-1i32; STRIDE];
        let mut value_next = [0i32; STRIDE];
        for position in 0..=n {
            let value = horizontal[a][position] as usize;
            value_next[position] = value_head[value];
            value_head[value] = position as i32;
        }
        let mut fenwick = [0i32; STRIDE + 1];
        for b in 0..=n {
            let mut position = value_head[b];
            while position >= 0 {
                fenwick_add(&mut fenwick, position as usize, n + 1);
                position = value_next[position as usize];
            }
            let mut query_index = query_head[a * STRIDE + b];
            while query_index >= 0 {
                let qi = query_index as usize;
                let query = queries[qi];
                answers[qi] = fenwick_prefix(&fenwick, query.c + 1)
                    - fenwick_prefix(&fenwick, query.b + 1);
                query_index = query_next[qi];
            }
        }
    }
    for index in 0..q { store_i64_le(output, 8 * index, i64::from(answers[index])); }
    output_bytes as i64
}
