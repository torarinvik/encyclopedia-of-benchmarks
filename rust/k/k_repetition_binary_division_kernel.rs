use std::slice;

const MAX_N: usize = 32;
const MAX_K: usize = 3;
const MAX_INPUT: usize = 35;
const MAX_PERIODS: usize = 17;
const BIT_WORDS: usize = 272;
const MAX_FACTORS: usize = 33;
const MAX_OUTPUT: usize = 91_400;

struct Search {
    text: [i32; MAX_N],
    n: usize,
    budget: usize,
    starts: [usize; MAX_FACTORS],
    ends: [usize; MAX_FACTORS],
    factor_count: usize,
    seen: [u64; BIT_WORDS],
}

impl Search {
    fn lp(w: &[i32], center: usize, period: usize, allowed: usize) -> usize {
        let left = center - period;
        let limit = (w.len() - left).min(w.len() - center);
        let mut errors = 0;
        for j in 0..limit {
            if w[left + j] != w[center + j] {
                errors += 1;
                if errors > allowed { return j; }
            }
        }
        limit
    }

    fn ls(w: &[i32], center: usize, period: usize, allowed: usize) -> usize {
        let limit = (center - period).min(center);
        let mut errors = 0;
        for j in 0..limit {
            if w[center - period - 1 - j] != w[center - 1 - j] {
                errors += 1;
                if errors > allowed { return j; }
            }
        }
        limit
    }

    fn mark(&mut self, lo: usize, last_head: usize, start: usize, end: usize, period: usize) {
        let start = start + lo;
        let end = end + lo;
        if start <= lo || end >= self.n || end - start + 1 < 2 * period { return; }
        if start <= last_head + 1 && end + 1 >= last_head { return; }
        let index = (start * MAX_N + end) * MAX_PERIODS + period;
        self.seen[index / 64] |= 1u64 << (index % 64);
    }

    fn at_center(&mut self, w: &[i32], center: usize, lo: usize, last_head: usize) {
        if center == 0 || center + 1 >= w.len() { return; }
        for period in 1..=center {
            for k in 0..=self.budget {
                let forward = Self::lp(w, center, period, k);
                let backward = Self::ls(w, center, period, self.budget - k);
                if forward <= period && forward + backward >= period {
                    self.mark(lo, last_head, center - period - backward,
                              center + forward - 1, period);
                }
            }
        }
        let reversed: Vec<i32> = w.iter().rev().copied().collect();
        let rc = w.len() - 1 - center;
        for period in 1..=rc {
            for k in 0..=self.budget {
                let forward = Self::lp(&reversed, rc, period, k);
                let backward = Self::ls(&reversed, rc, period, self.budget - k);
                if forward <= period && forward + backward >= period {
                    let rs = rc - period - backward;
                    let re = rc + forward - 1;
                    self.mark(lo, last_head, w.len() - 1 - re,
                              w.len() - 1 - rs, period);
                }
            }
        }
    }

    fn divide(&mut self, first: usize, last: usize) {
        if first >= last { return; }
        let mid = first + (last - first) / 2;
        let lo = self.starts[first];
        let hi = self.ends[last];
        let center = self.ends[mid] - 1;
        let last_head = self.ends[last] - 1;
        let local = self.text[lo..hi].to_vec();
        self.at_center(&local, center - lo, lo, last_head);
        self.divide(first, mid);
        self.divide(mid + 1, last);
    }
}

fn encode_i64(output: *mut u8, offset: usize, value: u64) {
    for byte in 0..8 { unsafe { *output.add(offset + byte) = (value >> (8 * byte)) as u8; } }
}

#[no_mangle]
pub unsafe extern "C" fn k_repetition_binary_division_kernel(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let input = slice::from_raw_parts(values, length);
    if !(1..=MAX_N as i64).contains(&input[0]) || !(0..=MAX_K as i64).contains(&input[1]) { return -1; }
    let n = input[0] as usize;
    let budget = input[1] as usize;
    if length != n + 2 { return -1; }
    let mut state = Search { text: [0; MAX_N], n, budget,
        starts: [0; MAX_FACTORS], ends: [0; MAX_FACTORS], factor_count: 0,
        seen: [0; BIT_WORDS] };
    for i in 0..n {
        if !(0..=4).contains(&input[i + 2]) { return -1; }
        state.text[i] = input[i + 2] as i32;
    }
    if state.text[..n - 1].contains(&state.text[n - 1]) { return -1; }
    let mut pos = 0;
    while pos < n {
        let mut best = 0;
        for earlier in 0..pos {
            let mut matched = 0;
            while pos + matched < n && earlier + matched < n
                && state.text[earlier + matched] == state.text[pos + matched] { matched += 1; }
            best = best.max(matched);
        }
        let end = n.min(pos + best + 1);
        state.starts[state.factor_count] = pos;
        state.ends[state.factor_count] = end;
        state.factor_count += 1;
        pos = end;
    }
    let block = budget + 2;
    let mut first = 0;
    while first < state.factor_count {
        state.divide(first, state.factor_count.min(first + block) - 1);
        first += block;
    }
    let mut records = 0usize;
    for start in 0..n {
        for len in 2..=n - start {
            let end = start + len - 1;
            for period in 1..=len / 2 {
                let index = (start * MAX_N + end) * MAX_PERIODS + period;
                if state.seen[index / 64] & (1u64 << (index % 64)) != 0 { records += 1; }
            }
        }
    }
    let written = 8 + records * 32;
    if written > MAX_OUTPUT as usize { return -1; }
    if output.is_null() || capacity < written { return -2; }
    encode_i64(output, 0, records as u64);
    let mut offset = 8;
    for start in 0..n {
        for len in 2..=n - start {
            let end = start + len - 1;
            for period in 1..=len / 2 {
                let index = (start * MAX_N + end) * MAX_PERIODS + period;
                if state.seen[index / 64] & (1u64 << (index % 64)) == 0 { continue; }
                let mismatches = (start..=end - period).filter(|&i| state.text[i] != state.text[i + period]).count();
                for field in [start, len, period, mismatches] {
                    encode_i64(output, offset, field as u64);
                    offset += 8;
                }
            }
        }
    }
    written as i64
}
