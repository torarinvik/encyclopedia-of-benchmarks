const MAX_ITEMS: usize = 64;
const MAX_QUERIES: usize = 64;
const MAX_LEVELS: usize = 4;
const MAX_INPUT: usize = 195;
const VALUE_LIMIT: i64 = 1_000_000_000;

struct State {
    values: [i64; MAX_ITEMS],
    prefix: [[i64; MAX_ITEMS]; MAX_LEVELS],
    suffix: [[i64; MAX_ITEMS]; MAX_LEVELS],
    between: [[i64; MAX_ITEMS]; MAX_LEVELS],
    floor_log: [usize; MAX_ITEMS + 1],
    padded: usize,
    layer_count: usize,
    segment_bits: [usize; MAX_LEVELS],
    block_bits: [usize; MAX_LEVELS],
    layer_for_diff: [isize; MAX_LEVELS + 3],
}

impl State {
    fn new() -> Self {
        Self {
            values: [0; MAX_ITEMS], prefix: [[i64::MAX; MAX_ITEMS]; MAX_LEVELS],
            suffix: [[i64::MAX; MAX_ITEMS]; MAX_LEVELS], between: [[i64::MAX; MAX_ITEMS]; MAX_LEVELS],
            floor_log: [0; MAX_ITEMS + 1], padded: 1, layer_count: 0,
            segment_bits: [0; MAX_LEVELS], block_bits: [0; MAX_LEVELS],
            layer_for_diff: [-1; MAX_LEVELS + 3],
        }
    }

    fn build(&mut self, input: &[i64], n: usize) {
        let mut padded = 1;
        while padded < n { padded *= 2; }
        self.padded = padded;
        self.values[..n].copy_from_slice(&input[2..2 + n]);
        for i in n..padded { self.values[i] = i64::MAX; }
        for i in 2..=padded { self.floor_log[i] = self.floor_log[i / 2] + 1; }
        let mut bits = self.floor_log[padded];
        while bits > 1 {
            let level = self.layer_count;
            self.layer_count += 1;
            let block_bits = (bits + 1) / 2;
            self.segment_bits[level] = bits;
            self.block_bits[level] = block_bits;
            for bit in block_bits..bits { self.layer_for_diff[bit] = level as isize; }
            bits = block_bits;
        }
        for level in 0..self.layer_count {
            let segment_bits = self.segment_bits[level];
            let block_bits = self.block_bits[level];
            let segment_size = 1_usize << segment_bits;
            let block_size = 1_usize << block_bits;
            let block_count = segment_size / block_size;
            let pair_count = block_count * block_count;
            for base in (0..padded).step_by(segment_size) {
                let segment_index = base / segment_size;
                for block in 0..block_count {
                    let start = base + block * block_size;
                    let end = start + block_size;
                    self.prefix[level][start] = self.values[start];
                    for i in start + 1..end {
                        self.prefix[level][i] = self.prefix[level][i - 1].min(self.values[i]);
                    }
                    self.suffix[level][end - 1] = self.values[end - 1];
                    for i in (start..end - 1).rev() {
                        self.suffix[level][i] = self.values[i].min(self.suffix[level][i + 1]);
                    }
                }
                for left in 0..block_count {
                    let mut aggregate = i64::MAX;
                    for right in left..block_count {
                        let start = base + right * block_size;
                        aggregate = aggregate.min(self.suffix[level][start]);
                        let slot = segment_index * pair_count + left * block_count + right;
                        self.between[level][slot] = aggregate;
                    }
                }
            }
        }
    }

    fn query(&self, left: usize, right: usize) -> i64 {
        if left == right { return self.values[left]; }
        let bit = self.floor_log[left ^ right];
        if bit == 0 { return self.values[left].min(self.values[right]); }
        let level = self.layer_for_diff[bit] as usize;
        let segment_bits = self.segment_bits[level];
        let block_bits = self.block_bits[level];
        let segment_size = 1_usize << segment_bits;
        let block_size = 1_usize << block_bits;
        let base = (left / segment_size) * segment_size;
        let segment_index = base / segment_size;
        let block_count = segment_size / block_size;
        let left_block = (left - base) / block_size;
        let right_block = (right - base) / block_size;
        let mut answer = self.suffix[level][left].min(self.prefix[level][right]);
        if left_block + 1 < right_block {
            let pair_count = block_count * block_count;
            let slot = segment_index * pair_count + (left_block + 1) * block_count + right_block - 1;
            answer = answer.min(self.between[level][slot]);
        }
        answer
    }
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn sqrt_tree_constant_time(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n_value, q_value) = (values[0], values[1]);
    if !(1..=MAX_ITEMS as i64).contains(&n_value) || !(0..=MAX_QUERIES as i64).contains(&q_value) { return -1; }
    let n = n_value as usize;
    let q = q_value as usize;
    if length != 2 + n + 2 * q { return -1; }
    if values[2..2 + n].iter().any(|&x| !(-VALUE_LIMIT..=VALUE_LIMIT).contains(&x)) { return -1; }
    let query_offset = 2 + n;
    for query in 0..q {
        let left = values[query_offset + 2 * query];
        let right = values[query_offset + 2 * query + 1];
        if left < 0 || right < left || right >= n_value { return -1; }
    }
    let required = 8 * q;
    if output_capacity < required || (required != 0 && output.is_null()) { return -2; }
    let mut state = State::new();
    state.build(values, n);
    for query in 0..q {
        let left = values[query_offset + 2 * query] as usize;
        let right = values[query_offset + 2 * query + 1] as usize;
        store_i64_le(output, 8 * query, state.query(left, right));
    }
    required as i64
}
