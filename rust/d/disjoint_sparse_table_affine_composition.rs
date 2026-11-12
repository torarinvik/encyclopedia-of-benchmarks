use std::slice;

const MOD: i64 = 1_000_000_007;
const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_LEVELS: usize = 5;

#[derive(Clone, Copy, Default)]
struct Affine { a: i64, b: i64 }

fn combine(left: Affine, right: Affine) -> Affine {
    Affine {
        a: right.a * left.a % MOD,
        b: (right.a * left.b + right.b) % MOD,
    }
}

fn put_word(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn disjoint_sparse_table_affine_composition(
    input_ptr: *const i64,
    length: usize,
    output_ptr: *mut u8,
    capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 2 || length > 130 { return -1; }
    let input = slice::from_raw_parts(input_ptr, length);
    let (n_value, q_value) = (input[0], input[1]);
    if n_value < 1 || n_value > MAX_N as i64 || q_value < 1 || q_value > MAX_Q as i64 { return -1; }
    let (n, q) = (n_value as usize, q_value as usize);
    if length != 2 + 2 * n + 2 * q { return -1; }

    let mut maps = [Affine::default(); MAX_N];
    let mut left = [0usize; MAX_Q];
    let mut right = [0usize; MAX_Q];
    let mut cursor = 2;
    for item in maps.iter_mut().take(n) {
        let (a, b) = (input[cursor], input[cursor + 1]);
        cursor += 2;
        if a < 0 || a >= MOD || b < 0 || b >= MOD { return -1; }
        *item = Affine { a, b };
    }
    for query in 0..q {
        let (lo, hi) = (input[cursor], input[cursor + 1]);
        cursor += 2;
        if lo < 0 || lo > hi || hi >= n_value { return -1; }
        left[query] = lo as usize;
        right[query] = hi as usize;
    }
    let output_bytes = q * 16;
    if output_ptr.is_null() || capacity < output_bytes { return -2; }

    let mut table = [[Affine::default(); MAX_N]; MAX_LEVELS];
    let mut levels = 0;
    let mut span = 1;
    while span < n { levels += 1; span <<= 1; }
    for level in 0..levels {
        let half = 1usize << level;
        let width = half << 1;
        let mut start = 0;
        while start < n {
            let middle = (start + half).min(n);
            let end = (start + width).min(n);
            if middle > start {
                table[level][middle - 1] = maps[middle - 1];
                let mut index = middle - 1;
                while index > start {
                    table[level][index - 1] = combine(maps[index - 1], table[level][index]);
                    index -= 1;
                }
            }
            if middle < end {
                table[level][middle] = maps[middle];
                for index in (middle + 1)..end {
                    table[level][index] = combine(table[level][index - 1], maps[index]);
                }
            }
            start += width;
        }
    }
    let output = slice::from_raw_parts_mut(output_ptr, output_bytes);
    for query in 0..q {
        let answer = if left[query] == right[query] {
            maps[left[query]]
        } else {
            let mut difference = left[query] ^ right[query];
            let mut level = 0;
            while difference > 1 { difference >>= 1; level += 1; }
            combine(table[level][left[query]], table[level][right[query]])
        };
        put_word(output, query * 16, answer.a);
        put_word(output, query * 16 + 8, answer.b);
    }
    output_bytes as i64
}
