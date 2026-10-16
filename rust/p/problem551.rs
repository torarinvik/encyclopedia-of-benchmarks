const MAX_N: i64 = 1_000_000_000_000_000;
const STATE_CAPACITY: usize = 32_768;
const JUMP_CAPACITY: usize = 131_072;
const TABLE_MASK: usize = STATE_CAPACITY - 1;

#[derive(Clone, Copy)]
struct State { prefix_sum: i32, suffix: i64, head: i32 }
#[derive(Clone, Copy)]
struct Jump { difference: i64, terms: i64, k: i32, next: i32 }
struct Memo { states: Vec<State>, jumps: Vec<Jump>, jump_count: usize, failed: bool }
impl Memo {
    fn new() -> Self {
        Self {
            states: vec![State { prefix_sum: 0, suffix: 0, head: -2 }; STATE_CAPACITY],
            jumps: vec![Jump { difference: 0, terms: 0, k: 0, next: -1 }; JUMP_CAPACITY],
            jump_count: 0,
            failed: false,
        }
    }
    fn find_state(&mut self, prefix_sum: i64, suffix: i64) -> Option<usize> {
        let slot = ((suffix as usize % STATE_CAPACITY) + prefix_sum as usize * 1009) & TABLE_MASK;
        for probe in 0..STATE_CAPACITY {
            let index = (slot + probe) & TABLE_MASK;
            let state = self.states[index];
            if state.head == -2 {
                self.states[index] = State { prefix_sum: prefix_sum as i32, suffix, head: -1 };
                return Some(index);
            }
            if state.prefix_sum as i64 == prefix_sum && state.suffix == suffix { return Some(index); }
        }
        self.failed = true;
        None
    }
    fn add_jump(&mut self, state_index: usize, difference: i64, terms: i64, k: i64) {
        if self.jump_count >= JUMP_CAPACITY { self.failed = true; return; }
        let index = self.jump_count;
        self.jump_count += 1;
        self.jumps[index] = Jump {
            difference, terms, k: k as i32, next: self.states[state_index].head,
        };
        self.states[state_index].head = index as i32;
    }
}

fn power10(exponent: i64) -> i64 { let mut value = 1; for _ in 0..exponent { value *= 10; } value }
fn digit_sum(mut value: i64) -> i64 { let mut total = 0; while value > 0 { total += value % 10; value /= 10; } total }

fn compute(value: &mut i64, k: i64, mut index: i64, target: i64) -> (i64, i64) {
    let start = index;
    let base = power10(k);
    let prefix_sum = digit_sum(*value / base);
    let mut suffix = *value % base;
    let mut difference = 0;
    while index < target {
        index += 1;
        let addend = prefix_sum + digit_sum(suffix);
        difference += addend;
        suffix += addend;
        if suffix >= base { break; }
    }
    *value += difference;
    (difference, index - start)
}

fn next_term(value: &mut i64, k: i64, index: i64, target: i64, memo: &mut Memo) -> (i64, i64) {
    let base = power10(k);
    let prefix_sum = digit_sum(*value / base);
    let suffix = *value % base;
    let max_terms = target - index;
    let Some(state_index) = memo.find_state(prefix_sum, suffix) else { return (0, 0); };
    let mut difference = 0;
    let mut terms = 0;
    let mut best = -1_i32;
    let mut jump = memo.states[state_index].head;
    while jump >= 0 {
        let entry = memo.jumps[jump as usize];
        if entry.k as i64 <= k && entry.terms <= max_terms
            && (best < 0 || entry.terms > memo.jumps[best as usize].terms) {
            best = jump;
        }
        jump = entry.next;
    }
    if best >= 0 {
        let entry = memo.jumps[best as usize];
        difference = entry.difference;
        terms = entry.terms;
        *value += difference;
    }
    if terms >= max_terms || suffix + difference >= base { return (difference, terms); }
    if k > 2 {
        while !memo.failed {
            let (extra, jumped) = next_term(value, k - 1, index + terms, target, memo);
            difference += extra;
            terms += jumped;
            if terms >= max_terms || suffix + difference >= base { break; }
        }
    } else {
        let (extra, jumped) = compute(value, k, index + terms, target);
        difference += extra;
        terms += jumped;
    }
    if !memo.failed && terms < max_terms { memo.add_jump(state_index, difference, terms, k); }
    (difference, terms)
}

#[no_mangle]
pub extern "C" fn problem551(n: i64) -> i64 {
    if !(1..=MAX_N).contains(&n) { return -1; }
    let mut memo = Memo::new();
    let mut value = 1_i64;
    let mut jumped = 0_i64;
    while jumped != n - 1 && !memo.failed {
        let (_, terms) = next_term(&mut value, 18, 1 + jumped, n, &mut memo);
        jumped += terms;
    }
    if memo.failed { -1 } else { value }
}
