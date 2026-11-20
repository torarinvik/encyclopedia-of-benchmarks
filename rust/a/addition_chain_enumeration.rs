const MAX_TARGET: i64 = 31;
const OUTPUT_BYTES: usize = 24;

struct Search {
    target: i64,
    limit: usize,
    chain: [i64; 32],
    total_count: i64,
    brauer_count: i64,
}

impl Search {
    fn visit(&mut self, length: usize, prefix_is_brauer: bool) {
        let last = self.chain[length - 1];
        let steps = length - 1;
        if last == self.target {
            if steps == self.limit {
                self.total_count += 1;
                if prefix_is_brauer { self.brauer_count += 1; }
            }
            return;
        }
        let remaining = self.limit - steps;
        if remaining == 0 || last * (1_i64 << remaining) < self.target { return; }

        let mut generated = [false; 32];
        for left in 0..length {
            for right in left..length {
                let candidate = self.chain[left] + self.chain[right];
                if candidate <= last || candidate > self.target || generated[candidate as usize] { continue; }
                generated[candidate as usize] = true;
                self.chain[length] = candidate;
                let uses_last = (0..length).any(|index| last + self.chain[index] == candidate);
                self.visit(length + 1, prefix_is_brauer && uses_last);
            }
        }
    }
}

fn bit_length(mut value: i64) -> usize {
    let mut count = 0;
    while value != 0 { count += 1; value >>= 1; }
    count
}

fn popcount(mut value: i64) -> usize {
    let mut count = 0;
    while value != 0 { count += (value & 1) as usize; value >>= 1; }
    count
}

fn minimum_counts(target: i64) -> [i64; 3] {
    if target == 1 { return [0, 1, 0]; }
    let lower = bit_length(target - 1);
    let upper = bit_length(target) - 1 + popcount(target) - 1;
    for limit in lower..=upper {
        let mut state = Search {
            target, limit, chain: [0; 32], total_count: 0, brauer_count: 0,
        };
        state.chain[0] = 1;
        state.visit(1, true);
        if state.total_count != 0 {
            return [limit as i64, state.brauer_count, state.total_count - state.brauer_count];
        }
    }
    [0, 0, 0]
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (byte * 8)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn addition_chain_enumeration(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let target = *input;
    if !(1..=MAX_TARGET).contains(&target) { return -1; }
    let result = minimum_counts(target);
    if output.is_null() || output_capacity < OUTPUT_BYTES { return -2; }
    for index in 0..result.len() { store_i64_le(output, index * 8, result[index]); }
    OUTPUT_BYTES as i64
}
