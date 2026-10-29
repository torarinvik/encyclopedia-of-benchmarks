const MAX_OPERATIONS: i64 = 64;
const MAX_INPUT_LENGTH: usize = 1 + 3 * 64;
const MODULUS: i64 = 998_244_353;

#[derive(Clone, Copy)]
struct Affine {
    a: i64,
    b: i64,
}

const IDENTITY: Affine = Affine { a: 1, b: 0 };

fn compose(first: Affine, second: Affine) -> Affine {
    Affine {
        a: (second.a * first.a) % MODULUS,
        b: (second.a * first.b + second.b) % MODULUS,
    }
}

struct AggregateQueue {
    back_functions: [Affine; 64],
    back_aggregates: [Affine; 64],
    front_aggregates: [Affine; 64],
    back_size: usize,
    front_size: usize,
}

impl AggregateQueue {
    fn new() -> Self {
        Self {
            back_functions: [IDENTITY; 64],
            back_aggregates: [IDENTITY; 64],
            front_aggregates: [IDENTITY; 64],
            back_size: 0,
            front_size: 0,
        }
    }

    fn push_back(&mut self, a: i64, b: i64) {
        let function = Affine { a, b };
        self.back_functions[self.back_size] = function;
        self.back_aggregates[self.back_size] = if self.back_size == 0 {
            function
        } else {
            compose(self.back_aggregates[self.back_size - 1], function)
        };
        self.back_size += 1;
    }

    fn transfer(&mut self) {
        while self.back_size > 0 {
            self.back_size -= 1;
            let function = self.back_functions[self.back_size];
            self.front_aggregates[self.front_size] = if self.front_size == 0 {
                function
            } else {
                compose(function, self.front_aggregates[self.front_size - 1])
            };
            self.front_size += 1;
        }
    }

    fn pop_front(&mut self) -> bool {
        if self.front_size == 0 { self.transfer(); }
        if self.front_size == 0 { return false; }
        self.front_size -= 1;
        true
    }

    fn aggregate(&self) -> Affine {
        let mut result = IDENTITY;
        if self.front_size > 0 {
            result = self.front_aggregates[self.front_size - 1];
        }
        if self.back_size > 0 {
            result = if self.front_size > 0 {
                compose(result, self.back_aggregates[self.back_size - 1])
            } else {
                self.back_aggregates[self.back_size - 1]
            };
        }
        result
    }
}

#[no_mangle]
pub extern "C" fn queue_operate_all_composite(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(1..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(values, length) };
    if !(0..=MAX_OPERATIONS).contains(&packed[0]) { return -1; }
    let operation_count = packed[0] as usize;
    let mut queue = AggregateQueue::new();
    let mut position = 1usize;
    let mut checksum = 0i64;
    let mut query_number = 0i64;
    for _ in 0..operation_count {
        if position >= length { return -1; }
        let opcode = packed[position];
        position += 1;
        if opcode == 0 {
            if length - position < 2 { return -1; }
            let a = packed[position];
            let b = packed[position + 1];
            position += 2;
            if !(1..MODULUS).contains(&a) || !(0..MODULUS).contains(&b) { return -1; }
            queue.push_back(a, b);
        } else if opcode == 1 {
            if !queue.pop_front() { return -1; }
        } else if opcode == 2 {
            if position >= length { return -1; }
            let x = packed[position];
            position += 1;
            if !(0..MODULUS).contains(&x) { return -1; }
            let function = queue.aggregate();
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
