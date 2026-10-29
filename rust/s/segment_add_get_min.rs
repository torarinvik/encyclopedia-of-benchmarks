const MAX_INITIAL_SEGMENTS: i64 = 16;
const MAX_OPERATIONS: i64 = 32;
const DOMAIN_LOW: i64 = -32;
const DOMAIN_HIGH: i64 = 31;
const DOMAIN_RIGHT: i64 = 32;
const COEFFICIENT_LIMIT: i64 = 1_000;
const INFINITY_VALUE: i64 = 1_000_000_000_000;
const CHECKSUM_OFFSET: i64 = 33_001;
const TREE_CAPACITY: usize = 4 * 64 + 8;
const MAX_INPUT_LENGTH: usize = 2 + 4 * 16 + 5 * 32;

#[derive(Clone, Copy)]
struct Node {
    slope: i64,
    intercept: i64,
    occupied: bool,
}

const EMPTY_NODE: Node = Node { slope: 0, intercept: 0, occupied: false };

struct SegmentLiChao {
    nodes: [Node; TREE_CAPACITY],
}

impl SegmentLiChao {
    fn new() -> Self {
        Self { nodes: [EMPTY_NODE; TREE_CAPACITY] }
    }

    fn evaluate(slope: i64, intercept: i64, x: i64) -> i64 {
        slope * x + intercept
    }

    fn add_line(&mut self, node: usize, low: i64, high: i64, mut slope: i64, mut intercept: i64) {
        if !self.nodes[node].occupied {
            self.nodes[node] = Node { slope, intercept, occupied: true };
            return;
        }
        let middle = low + (high - low) / 2;
        if Self::evaluate(slope, intercept, middle)
            < Self::evaluate(self.nodes[node].slope, self.nodes[node].intercept, middle)
        {
            std::mem::swap(&mut slope, &mut self.nodes[node].slope);
            std::mem::swap(&mut intercept, &mut self.nodes[node].intercept);
        }
        if low == high { return; }
        if Self::evaluate(slope, intercept, low)
            < Self::evaluate(self.nodes[node].slope, self.nodes[node].intercept, low)
        {
            self.add_line(2 * node, low, middle, slope, intercept);
        } else if Self::evaluate(slope, intercept, high)
            < Self::evaluate(self.nodes[node].slope, self.nodes[node].intercept, high)
        {
            self.add_line(2 * node + 1, middle + 1, high, slope, intercept);
        }
    }

    fn add_segment(&mut self, node: usize, low: i64, high: i64,
                   query_low: i64, query_high: i64, slope: i64, intercept: i64) {
        if query_high <= low || high < query_low { return; }
        if query_low <= low && high < query_high {
            self.add_line(node, low, high, slope, intercept);
            return;
        }
        let middle = low + (high - low) / 2;
        self.add_segment(2 * node, low, middle, query_low, query_high, slope, intercept);
        self.add_segment(2 * node + 1, middle + 1, high, query_low, query_high, slope, intercept);
    }

    fn minimum_at(&self, node: usize, low: i64, high: i64, x: i64) -> i64 {
        let current = self.nodes[node];
        let mut best = if current.occupied {
            Self::evaluate(current.slope, current.intercept, x)
        } else {
            INFINITY_VALUE
        };
        if low == high { return best; }
        let middle = low + (high - low) / 2;
        let go_left = x <= middle;
        let nested = self.minimum_at(
            if go_left { 2 * node } else { 2 * node + 1 },
            if go_left { low } else { middle + 1 },
            if go_left { middle } else { high }, x,
        );
        best = best.min(nested);
        best
    }
}

fn valid_segment(left: i64, right: i64, slope: i64, intercept: i64) -> bool {
    (DOMAIN_LOW..DOMAIN_RIGHT).contains(&left)
        && left < right
        && right <= DOMAIN_RIGHT
        && (-COEFFICIENT_LIMIT..=COEFFICIENT_LIMIT).contains(&slope)
        && (-COEFFICIENT_LIMIT..=COEFFICIENT_LIMIT).contains(&intercept)
}

#[no_mangle]
pub extern "C" fn segment_add_get_min(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(2..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(values, length) };
    let initial_value = packed[0];
    let operation_value = packed[1];
    if !(0..=MAX_INITIAL_SEGMENTS).contains(&initial_value)
        || !(0..=MAX_OPERATIONS).contains(&operation_value)
    {
        return -1;
    }
    let initial_count = initial_value as usize;
    let operation_count = operation_value as usize;

    let mut tree = SegmentLiChao::new();
    let mut position = 2usize;
    for _ in 0..initial_count {
        if length - position < 4 { return -1; }
        let left = packed[position];
        let right = packed[position + 1];
        let slope = packed[position + 2];
        let intercept = packed[position + 3];
        if !valid_segment(left, right, slope, intercept) { return -1; }
        tree.add_segment(1, DOMAIN_LOW, DOMAIN_HIGH, left, right, slope, intercept);
        position += 4;
    }

    let mut checksum = 0i64;
    let mut query_number = 0i64;
    for _ in 0..operation_count {
        if position >= length { return -1; }
        let opcode = packed[position];
        position += 1;
        if opcode == 0 {
            if length - position < 4 { return -1; }
            let left = packed[position];
            let right = packed[position + 1];
            let slope = packed[position + 2];
            let intercept = packed[position + 3];
            if !valid_segment(left, right, slope, intercept) { return -1; }
            tree.add_segment(1, DOMAIN_LOW, DOMAIN_HIGH, left, right, slope, intercept);
            position += 4;
        } else if opcode == 1 {
            if position >= length { return -1; }
            let x = packed[position];
            position += 1;
            if !(DOMAIN_LOW..=DOMAIN_HIGH).contains(&x) { return -1; }
            let answer = tree.minimum_at(1, DOMAIN_LOW, DOMAIN_HIGH, x);
            query_number += 1;
            checksum += query_number * (answer + CHECKSUM_OFFSET);
        } else {
            return -1;
        }
    }
    if position != length { return -1; }
    checksum
}
