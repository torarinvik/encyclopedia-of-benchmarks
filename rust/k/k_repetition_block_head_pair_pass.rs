use std::slice;

const N: usize = 24;
const K: usize = 3;
const INPUT_MAX: usize = 27;
const CONTEXT_MAX: usize = 48;
const FACTORS: usize = 25;
const PERIODS: usize = 13;
const BIT_WORDS: usize = 117;
const OUTPUT_MAX: usize = 39_112;

struct State {
    word: [i32; N],
    starts: [usize; FACTORS],
    ends: [usize; FACTORS],
    seen: [u64; BIT_WORDS],
    n: usize,
    budget: usize,
    factor_count: usize,
}

impl State {
    fn right(w: &[i32], center: usize, period: usize, allowed: usize) -> usize {
        let limit = w.len() - center;
        let mut errors = 0;
        for d in 0..limit {
            if w[center - period + d] != w[center + d] {
                errors += 1;
                if errors > allowed { return d; }
            }
        }
        limit
    }

    fn left(w: &[i32], center: usize, period: usize, allowed: usize) -> usize {
        let limit = center - period;
        let mut errors = 0;
        for d in 0..limit {
            if w[center - period - 1 - d] != w[center - 1 - d] {
                errors += 1;
                if errors > allowed { return d; }
            }
        }
        limit
    }

    fn mark(&mut self, base: usize, size: usize, center: usize, next: usize,
            lo: usize, hi: usize, period: usize) {
        if hi >= size || hi - lo + 1 < 2 * period { return; }
        if lo > center + 1 || hi + 1 < center { return; }
        if lo <= next + 1 && hi + 1 >= next { return; }
        let start = base + lo;
        let end = base + hi;
        if end >= self.n { return; }
        let bit = (start * N + end) * PERIODS + period;
        self.seen[bit / 64] |= 1u64 << (bit % 64);
    }

    fn at_head(&mut self, w: &[i32], base: usize, center: usize, next: usize) {
        if center == 0 || center + 1 >= w.len() { return; }
        for period in 1..=center {
            for split in 0..=self.budget {
                let r = Self::right(w, center, period, split);
                let l = Self::left(w, center, period, self.budget - split);
                if r <= period && r + l >= period {
                    self.mark(base, w.len(), center, next, center - period - l,
                              center + r - 1, period);
                }
            }
        }
        let mut reverse = [0i32; CONTEXT_MAX];
        for i in 0..w.len() { reverse[i] = w[w.len() - 1 - i]; }
        let rev = &reverse[..w.len()];
        let rc = w.len() - 1 - center;
        for period in 1..=rc {
            for split in 0..=self.budget {
                let r = Self::right(&rev, rc, period, split);
                let l = Self::left(&rev, rc, period, self.budget - split);
                if r <= period && r + l >= period {
                    let rs = rc - period - l;
                    let re = rc + r - 1;
                    self.mark(base, w.len(), center, next, w.len() - 1 - re,
                              w.len() - 1 - rs, period);
                }
            }
        }
    }

    fn factorize(&mut self) {
        let mut pos = 0;
        while pos < self.n {
            let mut best = 0;
            for earlier in 0..pos {
                let mut matched = 0;
                while pos + matched < self.n && earlier + matched < self.n
                    && self.word[earlier + matched] == self.word[pos + matched] { matched += 1; }
                best = best.max(matched);
            }
            self.starts[self.factor_count] = pos;
            let end = self.n.min(pos + best + 1);
            self.ends[self.factor_count] = end;
            self.factor_count += 1;
            pos = end;
        }
    }

    fn run(&mut self) {
        let block = self.budget + 2;
        let blocks = (self.factor_count + block - 1) / block;
        for bi in 0..blocks.saturating_sub(1) {
            let first = bi * block;
            let first_end = self.factor_count.min(first + block);
            let second_end = self.factor_count.min(first_end + block);
            let head = self.ends[first_end - 1] - 1;
            let next_head = self.ends[second_end - 1] - 1;
            let pair_start = self.starts[first];
            let pair_end = self.ends[second_end - 1];
            let span = pair_end - pair_start;
            let base = pair_start.saturating_sub(span);
            let size = pair_end - base;
            let mut local = [0i32; CONTEXT_MAX];
            local[..size].copy_from_slice(&self.word[base..pair_end]);
            self.at_head(&local[..size], base, head - base, next_head - base);
        }
    }

    fn marked(&self, start: usize, end: usize, period: usize) -> bool {
        let bit = (start * N + end) * PERIODS + period;
        self.seen[bit / 64] & (1u64 << (bit % 64)) != 0
    }
}

unsafe fn put_word(output: *mut u8, offset: usize, value: u64) {
    for byte in 0..8 { *output.add(offset + byte) = (value >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn k_repetition_block_head_pair_pass(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 3 || length > INPUT_MAX { return -1; }
    let input = slice::from_raw_parts(values, length);
    if !(1..=N as i64).contains(&input[0]) || !(0..=K as i64).contains(&input[1]) { return -1; }
    let n = input[0] as usize;
    let budget = input[1] as usize;
    if length != n + 2 { return -1; }
    let mut state = State { word: [0; N], starts: [0; FACTORS], ends: [0; FACTORS],
        seen: [0; BIT_WORDS], n, budget, factor_count: 0 };
    for i in 0..n {
        if !(0..=4).contains(&input[i + 2]) { return -1; }
        state.word[i] = input[i + 2] as i32;
    }
    if state.word[..n - 1].contains(&state.word[n - 1]) { return -1; }
    state.factorize();
    state.run();
    let mut count = 0usize;
    for start in 0..n {
        for len in 2..=n - start {
            let end = start + len - 1;
            for period in 1..=len / 2 { if state.marked(start, end, period) { count += 1; } }
        }
    }
    let bytes = 8 + count * 32;
    if bytes > OUTPUT_MAX { return -1; }
    if output.is_null() || capacity < bytes { return -2; }
    put_word(output, 0, count as u64);
    let mut cursor = 8;
    for start in 0..n {
        for len in 2..=n - start {
            let end = start + len - 1;
            for period in 1..=len / 2 {
                if !state.marked(start, end, period) { continue; }
                let errors = (start..=end - period)
                    .filter(|&i| state.word[i] != state.word[i + period]).count();
                for field in [start, len, period, errors] {
                    put_word(output, cursor, field as u64);
                    cursor += 8;
                }
            }
        }
    }
    bytes as i64
}
