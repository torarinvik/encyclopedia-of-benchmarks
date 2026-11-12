const MAX_OPERATIONS: i64 = 64;
const MAX_INPUT_LENGTH: usize = 1 + 3 * 64;
const TREE_BASE: usize = 128;
const TREE_NODES: usize = 256;
const MODULUS: i64 = 998_244_353;

#[derive(Clone, Copy)]
struct Affine { a: i64, b: i64 }

const IDENTITY: Affine = Affine { a: 1, b: 0 };

fn compose(first: Affine, second: Affine) -> Affine {
    Affine {
        a: (second.a * first.a) % MODULUS,
        b: (second.a * first.b + second.b) % MODULUS,
    }
}

struct AggregateDeque {
    tree: [Affine; TREE_NODES],
    head: usize,
    tail: usize,
}

impl AggregateDeque {
    fn new() -> Self {
        Self { tree: [IDENTITY; TREE_NODES], head: 64, tail: 64 }
    }

    fn update(&mut self, position: usize, value: Affine) {
        let mut node = TREE_BASE + position;
        self.tree[node] = value;
        while node > 1 {
            node >>= 1;
            self.tree[node] = compose(self.tree[node * 2], self.tree[node * 2 + 1]);
        }
    }
}

#[no_mangle]
pub extern "C" fn deque_operate_all_composite(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(1..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(values, length) };
    if !(0..=MAX_OPERATIONS).contains(&packed[0]) { return -1; }
    let operation_count = packed[0] as usize;
    let mut deque = AggregateDeque::new();
    let mut position = 1usize;
    let mut checksum = 0i64;
    let mut query_number = 0i64;

    for _ in 0..operation_count {
        if position >= length { return -1; }
        let opcode = packed[position];
        position += 1;
        if opcode == 0 || opcode == 1 {
            if length - position < 2 { return -1; }
            let a = packed[position];
            let b = packed[position + 1];
            position += 2;
            if !(1..MODULUS).contains(&a) || !(0..MODULUS).contains(&b) { return -1; }
            let function = Affine { a, b };
            if opcode == 0 {
                if deque.head == 0 { return -1; }
                deque.head -= 1;
                deque.update(deque.head, function);
            } else {
                if deque.tail == TREE_BASE { return -1; }
                let tail = deque.tail;
                deque.tail += 1;
                deque.update(tail, function);
            }
        } else if opcode == 2 || opcode == 3 {
            if deque.head == deque.tail { return -1; }
            if opcode == 2 {
                let head = deque.head;
                deque.head += 1;
                deque.update(head, IDENTITY);
            } else {
                deque.tail -= 1;
                deque.update(deque.tail, IDENTITY);
            }
        } else if opcode == 4 {
            if position >= length { return -1; }
            let x = packed[position];
            position += 1;
            if !(0..MODULUS).contains(&x) { return -1; }
            let function = deque.tree[1];
            let answer = (function.a * x + function.b) % MODULUS;
            query_number += 1;
            checksum += query_number * (answer + 1);
        } else {
            return -1;
        }
    }
    if position != length { return -1; }
    checksum
}
