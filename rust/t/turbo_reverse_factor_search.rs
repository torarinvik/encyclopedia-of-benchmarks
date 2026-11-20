const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT: usize = 4227;
const MAX_STATES: usize = 2 * MAX_PATTERN + 2;
const ROOT: usize = 0;
const ARTIFICIAL: usize = 1;

struct Automaton {
    transition: [[i64; 4]; MAX_STATES],
    displacement: [[i64; 4]; MAX_STATES],
    suffix_link: [i64; MAX_STATES],
    max_length: [i64; MAX_STATES],
    position: [i64; MAX_STATES],
    terminal: [i64; MAX_STATES],
    state_count: usize,
}

impl Automaton {
    fn new() -> Self {
        Self {
            transition: [[-1; 4]; MAX_STATES],
            displacement: [[0; 4]; MAX_STATES],
            suffix_link: [-1; MAX_STATES],
            max_length: [0; MAX_STATES],
            position: [0; MAX_STATES],
            terminal: [0; MAX_STATES],
            state_count: 2,
        }
    }

    fn build(&mut self, pattern: &[i64]) -> bool {
        self.suffix_link[ROOT] = ARTIFICIAL as i64;
        let mut last = ROOT;
        for offset in 0..pattern.len() {
            let symbol = pattern[pattern.len() - 1 - offset] as usize;
            if self.state_count >= MAX_STATES { return false; }
            let current = self.state_count;
            self.state_count += 1;
            self.max_length[current] = self.max_length[last] + 1;
            self.position[current] = self.position[last] + 1;
            let mut state = last as i64;
            while state != ROOT as i64 && self.transition[state as usize][symbol] < 0 {
                self.transition[state as usize][symbol] = current as i64;
                self.displacement[state as usize][symbol] =
                    self.position[current] - self.position[state as usize] - 1;
                state = self.suffix_link[state as usize];
            }
            let target = self.transition[state as usize][symbol];
            if target < 0 {
                self.transition[ROOT][symbol] = current as i64;
                self.displacement[ROOT][symbol] =
                    self.position[current] - self.position[ROOT] - 1;
                self.suffix_link[current] = ROOT as i64;
            } else if self.max_length[state as usize] + 1 == self.max_length[target as usize] {
                self.suffix_link[current] = target;
            } else {
                if self.state_count >= MAX_STATES { return false; }
                let clone = self.state_count;
                self.state_count += 1;
                self.transition[clone] = self.transition[target as usize];
                self.displacement[clone] = self.displacement[target as usize];
                self.suffix_link[clone] = self.suffix_link[target as usize];
                self.max_length[clone] = self.max_length[state as usize] + 1;
                self.position[clone] = self.position[target as usize];
                self.terminal[clone] = self.terminal[target as usize];
                self.suffix_link[target as usize] = clone as i64;
                self.suffix_link[current] = clone as i64;
                while state != ARTIFICIAL as i64 {
                    let old_target = self.transition[state as usize][symbol];
                    if old_target < 0 || self.max_length[old_target as usize] < self.max_length[clone] {
                        break;
                    }
                    self.displacement[state as usize][symbol] =
                        self.position[old_target as usize] - self.position[state as usize] - 1;
                    self.transition[state as usize][symbol] = clone as i64;
                    state = self.suffix_link[state as usize];
                }
            }
            last = current;
        }
        self.terminal[last] = 1;
        while last != ROOT {
            last = self.suffix_link[last] as usize;
            self.terminal[last] = 1;
        }
        true
    }
}

fn mp_next(pattern: &[i64], next: &mut [i64; MAX_PATTERN + 1]) {
    let (mut i, mut border) = (0i64, -1i64);
    next[0] = -1;
    while (i as usize) < pattern.len() {
        while border >= 0 && pattern[i as usize] != pattern[border as usize] {
            border = next[border as usize];
        }
        i += 1;
        border += 1;
        next[i as usize] = border;
    }
}

fn search(aut: &Automaton, text: &[i64], m: usize, mp: &[i64; MAX_PATTERN + 1]) -> i64 {
    if text.len() < m { return 0; }
    let period = m as i64 - mp[m];
    let (mut count, mut sum, mut xor_offsets) = (0i64, 0i64, 0i64);
    let mut start = 0usize;
    let mut preceding_shift = m as i64;
    while start <= text.len() - m {
        let mut index = m as i64 - 1;
        let mut state = ROOT;
        let mut boundary = m as i64 - 1 - preceding_shift;
        let prefix_length = m as i64 - preceding_shift;
        let prefix_period = if preceding_shift != m as i64 {
            prefix_length - mp[prefix_length as usize]
        } else { 0 };
        let mut shift = m as i64;
        let mut displacement_sum = 0i64;

        while index > boundary {
            let symbol = text[start + index as usize] as usize;
            let target = aut.transition[state][symbol];
            if target < 0 { break; }
            displacement_sum += aut.displacement[state][symbol];
            state = target as usize;
            if aut.terminal[state] != 0 { shift = index; }
            index -= 1;
        }
        if index <= boundary {
            if displacement_sum == 0 {
                count += 1;
                sum += start as i64;
                xor_offsets ^= start as i64;
                shift = period;
            } else {
                let half = (boundary + 1) / 2;
                if prefix_period <= half {
                    boundary -= prefix_period;
                    while index > boundary {
                        let symbol = text[start + index as usize] as usize;
                        let target = aut.transition[state][symbol];
                        if target < 0 { break; }
                        displacement_sum += aut.displacement[state][symbol];
                        state = target as usize;
                        if aut.terminal[state] != 0 { shift = index; }
                        index -= 1;
                    }
                    if index <= boundary { shift = displacement_sum; }
                } else {
                    boundary = boundary - half - 1;
                    while index > boundary {
                        let symbol = text[start + index as usize] as usize;
                        let target = aut.transition[state][symbol];
                        if target < 0 { break; }
                        displacement_sum += aut.displacement[state][symbol];
                        state = target as usize;
                        if aut.terminal[state] != 0 { shift = index; }
                        index -= 1;
                    }
                }
            }
        }
        if shift <= 0 { return -1; }
        start += shift as usize;
        preceding_shift = shift;
    }
    (count << 36) | (sum << 12) | xor_offsets
}

#[no_mangle]
pub unsafe extern "C" fn turbo_reverse_factor_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=MAX_INPUT).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let nv = values[0];
    let mv = values[1];
    if nv < 0 || nv > MAX_TEXT as i64 || mv < 1 || mv > MAX_PATTERN as i64 { return -1; }
    let n = nv as usize;
    let m = mv as usize;
    if length != 2 + n + m { return -1; }
    if values[2..].iter().any(|&symbol| !(0..=3).contains(&symbol)) { return -1; }
    let pattern = &values[2 + n..];
    let mut aut = Automaton::new();
    if !aut.build(pattern) { return -1; }
    let mut mp = [0i64; MAX_PATTERN + 1];
    mp_next(pattern, &mut mp);
    search(&aut, &values[2..2 + n], m, &mp)
}
