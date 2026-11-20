use std::slice;

const N: usize = 16;
const K: i64 = 3;
const INPUT_MAX: usize = 1557;
const RECORD_MAX: usize = 372;
const PERIODS: usize = 9;
const BIT_WORDS: usize = 39;
const OUTPUT_MAX: usize = 11912;

#[derive(Clone, Copy, Default)]
struct Record { start: i32, end: i32, period: i32, errors: i32 }

struct State {
    word: [i32; N],
    starts: [i32; N],
    ends: [i32; N],
    copies: [i32; N],
    records: [Record; RECORD_MAX],
    known: [u64; BIT_WORDS],
    generated: [u64; BIT_WORDS],
    n: usize,
    budget: i32,
    factor_count: usize,
    record_count: usize,
}

impl State {
    fn new(n: usize, budget: i32) -> Self {
        Self { word: [0; N], starts: [0; N], ends: [0; N], copies: [0; N],
            records: [Record::default(); RECORD_MAX], known: [0; BIT_WORDS],
            generated: [0; BIT_WORDS], n, budget, factor_count: 0, record_count: 0 }
    }

    fn lce(&self, left: usize, right: usize) -> usize {
        let mut length = 0;
        while left + length < self.n && right + length < self.n
            && self.word[left + length] == self.word[right + length] { length += 1; }
        length
    }

    fn bit(start: usize, end: usize, period: usize) -> usize {
        (start * (N + 1) + end) * PERIODS + period
    }

    fn contains(bits: &[u64; BIT_WORDS], bit: usize) -> bool {
        bits[bit / 64] & (1u64 << (bit % 64)) != 0
    }

    fn less(a: Record, b: Record) -> bool {
        (a.start, a.end, a.period, a.errors) < (b.start, b.end, b.period, b.errors)
    }

    fn add(&mut self, record: Record, is_generated: bool) {
        let bit = Self::bit(record.start as usize, record.end as usize, record.period as usize);
        if Self::contains(&self.known, bit) { return; }
        self.known[bit / 64] |= 1u64 << (bit % 64);
        if is_generated { self.generated[bit / 64] |= 1u64 << (bit % 64); }
        let mut at = self.record_count;
        while at > 0 && Self::less(record, self.records[at - 1]) {
            self.records[at] = self.records[at - 1];
            at -= 1;
        }
        self.records[at] = record;
        self.record_count += 1;
    }

    fn factors_valid(&self) -> bool {
        if self.factor_count == 0 || self.factor_count > self.n { return false; }
        let mut position = 0usize;
        for f in 0..self.factor_count {
            let a = self.starts[f];
            let b = self.ends[f];
            let c = self.copies[f];
            if a < 0 || b <= a || b as usize > self.n || a as usize != position { return false; }
            if f == 0 {
                if a != 0 || b != 1 || c != -1 { return false; }
                position = b as usize;
                continue;
            }
            let a = a as usize;
            let mut longest = 0;
            for earlier in 0..a { longest = longest.max(self.lce(earlier, a)); }
            let expected_end = self.n.min(a + longest + 1);
            if b as usize != expected_end { return false; }
            let prefix = expected_end - a - 1;
            if prefix == 0 {
                if c != -1 { return false; }
            } else if c < 0 || c as usize >= a || self.lce(c as usize, a) != prefix {
                return false;
            }
            position = expected_end;
        }
        position == self.n
    }

    fn mismatches(&self, start: usize, end: usize, period: usize) -> usize {
        (start..end - period).filter(|&i| self.word[i] != self.word[i + period]).count()
    }

    fn seed_valid(&self, r: Record) -> bool {
        if r.start < 0 || r.end <= r.start || r.end as usize > self.n || r.period < 1 { return false; }
        let (a, b, p) = (r.start as usize, r.end as usize, r.period as usize);
        if p > self.n / 2 || b - a < 2 * p { return false; }
        let errors = self.mismatches(a, b, p);
        if errors != r.errors as usize || errors > self.budget as usize { return false; }
        if a > 0 && errors + usize::from(self.word[a - 1] != self.word[a + p - 1]) <= self.budget as usize { return false; }
        if b < self.n && errors + usize::from(self.word[b - p] != self.word[b]) <= self.budget as usize { return false; }
        true
    }

    fn propagate(&mut self) {
        for f in 0..self.factor_count {
            let a = self.starts[f] as usize;
            let b = self.ends[f] as usize;
            let c = self.copies[f] as isize;
            let copied = b - a - 1;
            if copied == 0 { continue; }
            let delta = a as isize - c;
            let copy_end = c as usize + copied;
            for target in a + 1..b.saturating_sub(1) {
                let source_start = (target as isize - delta) as usize;
                let mut index = 0;
                while index < self.record_count && self.records[index].start < source_start as i32 { index += 1; }
                while index < self.record_count && self.records[index].start == source_start as i32 {
                    let source = self.records[index];
                    if source.end as usize > copy_end { break; }
                    let target_end = source.end as usize + delta as usize;
                    if target_end <= b - 2 {
                        self.add(Record { start: target as i32, end: target_end as i32,
                            period: source.period, errors: source.errors }, true);
                    }
                    index += 1;
                }
            }
        }
    }
}

unsafe fn put(output: *mut u8, offset: usize, value: u64) {
    for byte in 0..8 { *output.add(offset + byte) = (value >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn k_repetition_within_factor_copy_propagation(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > INPUT_MAX { return -1; }
    let input = slice::from_raw_parts(values, length);
    if !(1..=N as i64).contains(&input[0]) || !(0..=K).contains(&input[1]) { return -1; }
    let n = input[0] as usize;
    let budget = input[1] as i32;
    if length < n + 3 { return -1; }
    let mut state = State::new(n, budget);
    let mut cursor = 2usize;
    for i in 0..n {
        if !(0..=5).contains(&input[cursor]) { return -1; }
        state.word[i] = input[cursor] as i32;
        cursor += 1;
    }
    if state.word[..n - 1].contains(&state.word[n - 1]) { return -1; }
    if cursor >= length || input[cursor] < 1 || input[cursor] > n as i64 { return -1; }
    state.factor_count = input[cursor] as usize;
    cursor += 1;
    if cursor + 3 * state.factor_count >= length { return -1; }
    for i in 0..state.factor_count {
        let (a, b, c) = (input[cursor], input[cursor + 1], input[cursor + 2]);
        if a < 0 || a > n as i64 || b < 0 || b > n as i64 || c < -1 || c > n as i64 { return -1; }
        state.starts[i] = a as i32; state.ends[i] = b as i32; state.copies[i] = c as i32;
        cursor += 3;
    }
    if cursor >= length || !state.factors_valid() { return -1; }
    let seed_count = input[cursor];
    cursor += 1;
    if seed_count < 0 || seed_count > RECORD_MAX as i64 || cursor + 4 * seed_count as usize != length { return -1; }
    for _ in 0..seed_count as usize {
        let r = Record { start: input[cursor] as i32, end: input[cursor + 1] as i32,
            period: input[cursor + 2] as i32, errors: input[cursor + 3] as i32 };
        if input[cursor] < 0 || input[cursor] > n as i64 || input[cursor + 1] < 0 || input[cursor + 1] > n as i64
            || input[cursor + 2] < 0 || input[cursor + 2] > n as i64 || input[cursor + 3] < 0 || input[cursor + 3] > K { return -1; }
        if !state.seed_valid(r) { return -1; }
        state.add(r, false);
        cursor += 4;
    }
    state.propagate();
    let count = (0..state.record_count).filter(|&i| {
        let r = state.records[i];
        State::contains(&state.generated, State::bit(r.start as usize, r.end as usize, r.period as usize))
    }).count();
    let bytes = 8 + 32 * count;
    if bytes > OUTPUT_MAX { return -1; }
    if output.is_null() || capacity < bytes { return -2; }
    put(output, 0, count as u64);
    let mut offset = 8;
    for i in 0..state.record_count {
        let r = state.records[i];
        if !State::contains(&state.generated, State::bit(r.start as usize, r.end as usize, r.period as usize)) { continue; }
        for value in [r.start, r.end, r.period, r.errors] {
            put(output, offset, value as u64);
            offset += 8;
        }
    }
    bytes as i64
}
