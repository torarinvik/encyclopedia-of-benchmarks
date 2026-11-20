const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT: usize = 4227;
const MAX_STATES: usize = 2 * MAX_PATTERN + 2;

struct SuffixAutomaton {
    transition: [[i64; 4]; MAX_STATES],
    suffix_link: [i64; MAX_STATES],
    max_length: [i64; MAX_STATES],
    state_count: usize,
}

impl SuffixAutomaton {
    fn new() -> Self {
        Self {
            transition: [[-1; 4]; MAX_STATES],
            suffix_link: [-1; MAX_STATES],
            max_length: [0; MAX_STATES],
            state_count: 1,
        }
    }

    fn extend(&mut self, last: i64, symbol: usize) -> i64 {
        if self.state_count >= MAX_STATES {
            return -1;
        }
        let current = self.state_count;
        self.state_count += 1;
        self.max_length[current] = self.max_length[last as usize] + 1;
        let mut state = last;
        while state >= 0 && self.transition[state as usize][symbol] < 0 {
            self.transition[state as usize][symbol] = current as i64;
            state = self.suffix_link[state as usize];
        }
        if state < 0 {
            self.suffix_link[current] = 0;
        } else {
            let target = self.transition[state as usize][symbol];
            if self.max_length[state as usize] + 1 == self.max_length[target as usize] {
                self.suffix_link[current] = target;
            } else {
                if self.state_count >= MAX_STATES {
                    return -1;
                }
                let clone = self.state_count;
                self.state_count += 1;
                self.transition[clone] = self.transition[target as usize];
                self.suffix_link[clone] = self.suffix_link[target as usize];
                self.max_length[clone] = self.max_length[state as usize] + 1;
                while state >= 0 && self.transition[state as usize][symbol] == target {
                    self.transition[state as usize][symbol] = clone as i64;
                    state = self.suffix_link[state as usize];
                }
                self.suffix_link[target as usize] = clone as i64;
                self.suffix_link[current] = clone as i64;
            }
        }
        current as i64
    }
}

fn search(sam: &SuffixAutomaton, text: &[i64], m: usize) -> i64 {
    let mut state = 0usize;
    let mut matched = 0i64;
    let (mut count, mut sum, mut xor_offsets) = (0i64, 0i64, 0i64);
    for (position, &value) in text.iter().enumerate() {
        let symbol = value as usize;
        let mut target = sam.transition[state][symbol];
        if target >= 0 {
            matched += 1;
            state = target as usize;
        } else {
            while state != 0 && sam.transition[state][symbol] < 0 {
                state = sam.suffix_link[state] as usize;
            }
            target = sam.transition[state][symbol];
            if target >= 0 {
                matched = sam.max_length[state] + 1;
                state = target as usize;
            } else {
                matched = 0;
                state = 0;
            }
        }
        if matched as usize == m {
            let start = (position + 1 - m) as i64;
            count += 1;
            sum += start;
            xor_offsets ^= start;
        }
    }
    (count << 36) | (sum << 12) | xor_offsets
}

#[no_mangle]
pub unsafe extern "C" fn forward_dawg_matching(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let m_value = values[1];
    if n_value < 0 || n_value > MAX_TEXT as i64 || m_value < 1 || m_value > MAX_PATTERN as i64 {
        return -1;
    }
    let n = n_value as usize;
    let m = m_value as usize;
    if length != 2 + n + m || values[2..].iter().any(|&v| !(0..=3).contains(&v)) {
        return -1;
    }
    let mut pattern = [0i64; MAX_PATTERN];
    pattern[..m].copy_from_slice(&values[2 + n..]);
    let mut sam = SuffixAutomaton::new();
    let mut last = 0i64;
    for &symbol in &pattern[..m] {
        last = sam.extend(last, symbol as usize);
        if last < 0 {
            return -1;
        }
    }
    search(&sam, &values[2..2 + n], m)
}
