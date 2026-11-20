use core::slice;

const MAX_INPUT: usize = 133;
const MAX_NODES: usize = 17_000;
const UNIQUE_CAP: usize = 32_768;

struct Manager {
    variable: [u8; MAX_NODES],
    low: [u16; MAX_NODES],
    high: [u16; MAX_NODES],
    unique: [u16; UNIQUE_CAP],
    exists_result: [u16; MAX_NODES],
    rename_result: [u16; MAX_NODES],
    next_id: u16,
    variable_count: u8,
    failed: bool,
}

impl Manager {
    fn new(variable_count: u8) -> Self {
        Self {
            variable: [0; MAX_NODES],
            low: [0; MAX_NODES],
            high: [0; MAX_NODES],
            unique: [0; UNIQUE_CAP],
            exists_result: [0; MAX_NODES],
            rename_result: [0; MAX_NODES],
            next_id: 2,
            variable_count,
            failed: false,
        }
    }

    fn unique_hash(variable: usize, low: usize, high: usize) -> usize {
        (variable * 4099 + low * 131 + high) & (UNIQUE_CAP - 1)
    }

    fn make_node(&mut self, variable: u8, low: u16, high: u16) -> u16 {
        if low == high {
            return low;
        }
        let mut slot = Self::unique_hash(variable as usize, low as usize, high as usize);
        for _ in 0..UNIQUE_CAP {
            let encoded = self.unique[slot];
            if encoded == 0 {
                if self.next_id as usize >= MAX_NODES {
                    self.failed = true;
                    return 0;
                }
                let id = self.next_id;
                self.next_id += 1;
                self.variable[id as usize] = variable;
                self.low[id as usize] = low;
                self.high[id as usize] = high;
                self.unique[slot] = id + 1;
                return id;
            }
            let id = (encoded - 1) as usize;
            if self.variable[id] == variable && self.low[id] == low && self.high[id] == high {
                return id as u16;
            }
            slot = (slot + 1) & (UNIQUE_CAP - 1);
        }
        self.failed = true;
        0
    }

    fn reset_round(&mut self, relation_end: u16) {
        self.unique.fill(0);
        self.exists_result.fill(0);
        self.rename_result.fill(0);
        self.next_id = relation_end;
        for id in 2..relation_end {
            let index = id as usize;
            let mut slot = Self::unique_hash(
                self.variable[index] as usize,
                self.low[index] as usize,
                self.high[index] as usize,
            );
            while self.unique[slot] != 0 {
                slot = (slot + 1) & (UNIQUE_CAP - 1);
            }
            self.unique[slot] = id + 1;
        }
    }

    fn top_variable(&self, node: u16) -> u8 {
        if node < 2 { self.variable_count } else { self.variable[node as usize] }
    }

    fn children_at(&self, node: u16, variable: u8) -> (u16, u16) {
        if node >= 2 && self.variable[node as usize] == variable {
            (self.low[node as usize], self.high[node as usize])
        } else {
            (node, node)
        }
    }

    fn apply_recursive(&mut self, left: u16, right: u16, is_or: bool) -> u16 {
        if self.failed {
            return 0;
        }
        if is_or {
            if left == 1 || right == 1 { return 1; }
            if left == 0 { return right; }
            if right == 0 || left == right { return left; }
        } else {
            if left == 0 || right == 0 { return 0; }
            if left == 1 { return right; }
            if right == 1 || left == right { return left; }
        }
        let variable = self.top_variable(left).min(self.top_variable(right));
        let (left_low, left_high) = self.children_at(left, variable);
        let (right_low, right_high) = self.children_at(right, variable);
        let result_low = self.apply_recursive(left_low, right_low, is_or);
        let result_high = self.apply_recursive(left_high, right_high, is_or);
        let result = self.make_node(variable, result_low, result_high);
        if self.failed {
            return 0;
        }
        result
    }

    fn apply_binary(&mut self, left: u16, right: u16, is_or: bool) -> u16 {
        self.apply_recursive(left, right, is_or)
    }

    fn truth_table_recursive(&mut self, bits: &[i64], variable: u8,
                             prefix: usize, variable_count: u8) -> u16 {
        if self.failed {
            return 0;
        }
        if variable == variable_count {
            return bits[prefix] as u16;
        }
        let low = self.truth_table_recursive(bits, variable + 1, prefix * 2, variable_count);
        let high = self.truth_table_recursive(bits, variable + 1, prefix * 2 + 1, variable_count);
        self.make_node(variable, low, high)
    }

    fn exists_recursive(&mut self, node: u16, quantified_variables: u8) -> u16 {
        if self.failed || node < 2 {
            return node;
        }
        let cached = self.exists_result[node as usize];
        if cached != 0 {
            return cached - 1;
        }
        let variable = self.variable[node as usize];
        let low_child = self.low[node as usize];
        let high_child = self.high[node as usize];
        let low = self.exists_recursive(low_child, quantified_variables);
        let high = self.exists_recursive(high_child, quantified_variables);
        let result = if variable < quantified_variables {
            self.apply_binary(low, high, true)
        } else {
            self.make_node(variable, low, high)
        };
        if !self.failed {
            self.exists_result[node as usize] = result + 1;
        }
        result
    }

    fn rename_recursive(&mut self, node: u16, first_variable: u8) -> u16 {
        if self.failed || node < 2 {
            return node;
        }
        let cached = self.rename_result[node as usize];
        if cached != 0 {
            return cached - 1;
        }
        let variable = self.variable[node as usize];
        if variable < first_variable {
            self.failed = true;
            return 0;
        }
        let low_child = self.low[node as usize];
        let high_child = self.high[node as usize];
        let low = self.rename_recursive(low_child, first_variable);
        let high = self.rename_recursive(high_child, first_variable);
        let result = self.make_node(variable - first_variable, low, high);
        if !self.failed {
            self.rename_result[node as usize] = result + 1;
        }
        result
    }

    fn evaluate(&self, mut node: u16, assignment: u16, variable_count: u8) -> u16 {
        while node >= 2 {
            let variable = self.variable[node as usize];
            let shift = variable_count - variable - 1;
            node = if ((assignment >> shift) & 1) != 0 {
                self.high[node as usize]
            } else {
                self.low[node as usize]
            };
        }
        node
    }
}

#[no_mangle]
pub unsafe extern "C" fn bdd_symbolic_reachability(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(4..=MAX_INPUT).contains(&length) {
        return -1;
    }
    let values = unsafe { slice::from_raw_parts(input, length) };
    let (n_raw, m_raw, initial_raw, invariant_raw) =
        (values[0], values[1], values[2], values[3]);
    if !(1..=3).contains(&n_raw) || !(0..=1).contains(&m_raw) {
        return -1;
    }
    let n = n_raw as u8;
    let m = m_raw as u8;
    let state_count = 1usize << n;
    let state_mask = (1i64 << state_count) - 1;
    let relation_length = 1usize << (2 * n + m);
    if initial_raw < 0 || invariant_raw < 0 || initial_raw & !state_mask != 0 ||
        invariant_raw & !state_mask != 0 || length != 4 + relation_length ||
        values[4..].iter().any(|&bit| bit != 0 && bit != 1) {
        return -1;
    }

    let mut manager = Manager::new(2 * n + m);
    let relation = manager.truth_table_recursive(&values[4..], 0, 0, 2 * n + m);
    if manager.failed {
        return -1;
    }
    let relation_end = manager.next_id;

    let mut reached_mask = initial_raw as u16;
    for iteration in 0..=state_count {
        manager.reset_round(relation_end);
        let mut reached_bits = [0i64; 8];
        for state in 0..state_count {
            reached_bits[state] = ((reached_mask >> state) & 1) as i64;
        }
        let reached = manager.truth_table_recursive(&reached_bits[..state_count], 0, 0, n);
        let product = manager.apply_binary(reached, relation, false);
        let mut next_set = manager.exists_recursive(product, n + m);
        next_set = manager.rename_recursive(next_set, n + m);
        let joined = manager.apply_binary(reached, next_set, true);
        if manager.failed {
            return -1;
        }
        if joined == reached {
            break;
        }
        reached_mask = 0;
        for state in 0..state_count {
            reached_mask |= manager.evaluate(joined, state as u16, n) << state;
        }
        if iteration == state_count {
            return -1;
        }
    }
    let violation = (reached_mask & !(invariant_raw as u16) != 0) as i64;
    ((reached_mask as i64) << 1) | violation
}
