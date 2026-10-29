const MAX_OPERATIONS: usize = 512;
const MAX_NODES: usize = MAX_OPERATIONS * 24 + 1;
const DOMAIN_LOW: i64 = -1_000_000;
const DOMAIN_HIGH: i64 = 1_000_000;
const COEFFICIENT_LIMIT: i64 = 1_000;
const CHECKSUM_OFFSET: i64 = 1_000_001_001;

#[derive(Clone, Copy)]
struct Node {
    slope: i64,
    intercept: i64,
    left: i32,
    right: i32,
    occupied: bool,
}

const EMPTY_NODE: Node = Node {
    slope: 0,
    intercept: 0,
    left: -1,
    right: -1,
    occupied: false,
};

struct LiChaoTree {
    nodes: [Node; MAX_NODES],
    used: usize,
    root: i32,
}

impl LiChaoTree {
    fn new() -> Self {
        Self { nodes: [EMPTY_NODE; MAX_NODES], used: 0, root: -1 }
    }

    fn evaluate(slope: i64, intercept: i64, x: i64) -> i64 {
        slope * x + intercept
    }

    fn allocate(&mut self) -> Option<i32> {
        if self.used == MAX_NODES { return None; }
        let id = self.used as i32;
        self.used += 1;
        Some(id)
    }

    fn insert_at(&mut self, id: i32, low: i64, high: i64, mut slope: i64, mut intercept: i64) -> bool {
        let index = id as usize;
        if !self.nodes[index].occupied {
            self.nodes[index].slope = slope;
            self.nodes[index].intercept = intercept;
            self.nodes[index].occupied = true;
            return true;
        }

        let middle = low + (high - low) / 2;
        if Self::evaluate(slope, intercept, middle)
            < Self::evaluate(self.nodes[index].slope, self.nodes[index].intercept, middle)
        {
            std::mem::swap(&mut slope, &mut self.nodes[index].slope);
            std::mem::swap(&mut intercept, &mut self.nodes[index].intercept);
        }
        if low == high { return true; }

        let (left_side, next_low, next_high) = if Self::evaluate(slope, intercept, low)
            < Self::evaluate(self.nodes[index].slope, self.nodes[index].intercept, low)
        {
            (true, low, middle)
        } else if Self::evaluate(slope, intercept, high)
            < Self::evaluate(self.nodes[index].slope, self.nodes[index].intercept, high)
        {
            (false, middle + 1, high)
        } else {
            return true;
        };

        let child = if left_side { self.nodes[index].left } else { self.nodes[index].right };
        let child = if child < 0 {
            let Some(created) = self.allocate() else { return false; };
            if left_side { self.nodes[index].left = created; } else { self.nodes[index].right = created; }
            created
        } else {
            child
        };
        self.insert_at(child, next_low, next_high, slope, intercept)
    }

    fn add(&mut self, slope: i64, intercept: i64) -> bool {
        if self.root < 0 {
            let Some(root) = self.allocate() else { return false; };
            self.root = root;
        }
        self.insert_at(self.root, DOMAIN_LOW, DOMAIN_HIGH, slope, intercept)
    }

    fn minimum_at(&self, id: i32, low: i64, high: i64, x: i64) -> i64 {
        let node = self.nodes[id as usize];
        let mut best = Self::evaluate(node.slope, node.intercept, x);
        if low == high { return best; }
        let middle = low + (high - low) / 2;
        let go_left = x <= middle;
        let child = if go_left { node.left } else { node.right };
        if child >= 0 {
            let nested = self.minimum_at(child,
                if go_left { low } else { middle + 1 },
                if go_left { middle } else { high }, x);
            best = best.min(nested);
        }
        best
    }
}

#[no_mangle]
pub extern "C" fn li_chao_tree(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(1..=1 + 3 * MAX_OPERATIONS).contains(&length) { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(values, length) };
    if !(0..=MAX_OPERATIONS as i64).contains(&packed[0]) { return -1; }
    let operation_count = packed[0] as usize;
    if length != 1 + 3 * operation_count { return -1; }

    let mut tree = LiChaoTree::new();
    let mut inserted = 0usize;
    let mut query_number = 0usize;
    let mut checksum = 0i64;
    for operation in 0..operation_count {
        let offset = 1 + 3 * operation;
        let opcode = packed[offset];
        let first = packed[offset + 1];
        let second = packed[offset + 2];
        if opcode == 0 {
            if !(-COEFFICIENT_LIMIT..=COEFFICIENT_LIMIT).contains(&first)
                || !(-COEFFICIENT_LIMIT..=COEFFICIENT_LIMIT).contains(&second)
                || !tree.add(first, second) { return -1; }
            inserted += 1;
        } else if opcode == 1 {
            if !(DOMAIN_LOW..=DOMAIN_HIGH).contains(&first) || second != 0 || inserted == 0 { return -1; }
            let answer = tree.minimum_at(tree.root, DOMAIN_LOW, DOMAIN_HIGH, first);
            query_number += 1;
            checksum += query_number as i64 * (answer + CHECKSUM_OFFSET);
        } else {
            return -1;
        }
    }
    checksum
}
