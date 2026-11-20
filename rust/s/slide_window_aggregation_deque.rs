const MAX_OPERATIONS: usize = 32;
const MAX_INPUT_LENGTH: usize = 162;
const MODULUS: i64 = 97;

#[derive(Clone, Copy)]
struct Matrix { a: i64, b: i64, c: i64, d: i64 }

const IDENTITY: Matrix = Matrix { a: 1, b: 0, c: 0, d: 1 };

fn multiply(x: Matrix, y: Matrix) -> Matrix {
    Matrix {
        a: (x.a * y.a + x.b * y.c) % MODULUS,
        b: (x.a * y.b + x.b * y.d) % MODULUS,
        c: (x.c * y.a + x.d * y.c) % MODULUS,
        d: (x.c * y.b + x.d * y.d) % MODULUS,
    }
}

fn pack(value: Matrix) -> i64 {
    value.a + MODULUS * value.b + MODULUS * MODULUS * value.c
        + MODULUS * MODULUS * MODULUS * value.d
}

fn push_front(items: &mut [Matrix; MAX_OPERATIONS], aggregates: &mut [Matrix; MAX_OPERATIONS],
              count: &mut usize, value: Matrix) {
    items[*count] = value;
    aggregates[*count] = if *count == 0 { value } else { multiply(value, aggregates[*count - 1]) };
    *count += 1;
}

fn push_back(items: &mut [Matrix; MAX_OPERATIONS], aggregates: &mut [Matrix; MAX_OPERATIONS],
             count: &mut usize, value: Matrix) {
    items[*count] = value;
    aggregates[*count] = if *count == 0 { value } else { multiply(aggregates[*count - 1], value) };
    *count += 1;
}

fn rebalance(front: &mut [Matrix; MAX_OPERATIONS], front_aggregates: &mut [Matrix; MAX_OPERATIONS],
             front_count: &mut usize, back: &mut [Matrix; MAX_OPERATIONS],
             back_aggregates: &mut [Matrix; MAX_OPERATIONS], back_count: &mut usize,
             temporary: &mut [Matrix; MAX_OPERATIONS]) {
    let front_was_empty = *front_count == 0;
    let total = *front_count + *back_count;
    for i in 0..*front_count { temporary[i] = front[*front_count - 1 - i]; }
    for i in 0..*back_count { temporary[*front_count + i] = back[i]; }
    let front_size = total / 2 + if front_was_empty { total % 2 } else { 0 };
    *front_count = 0;
    *back_count = 0;
    for i in (0..front_size).rev() {
        push_front(front, front_aggregates, front_count, temporary[i]);
    }
    for i in front_size..total {
        push_back(back, back_aggregates, back_count, temporary[i]);
    }
}

#[no_mangle]
pub extern "C" fn slide_window_aggregation_deque(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(1..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if !(0..=MAX_OPERATIONS as i64).contains(&input[0]) { return -1; }
    let operation_count = input[0] as usize;

    let mut front = [IDENTITY; MAX_OPERATIONS];
    let mut front_aggregates = [IDENTITY; MAX_OPERATIONS];
    let mut back = [IDENTITY; MAX_OPERATIONS];
    let mut back_aggregates = [IDENTITY; MAX_OPERATIONS];
    let mut temporary = [IDENTITY; MAX_OPERATIONS];
    let mut front_count = 0usize;
    let mut back_count = 0usize;
    let mut position = 1usize;
    let mut query_ordinal = 0i64;
    let mut checksum = 0i64;

    for _ in 0..operation_count {
        if position >= length { return -1; }
        let opcode = input[position];
        position += 1;
        if opcode == 0 || opcode == 1 {
            if length - position < 4 { return -1; }
            let value = Matrix { a: input[position], b: input[position + 1],
                                 c: input[position + 2], d: input[position + 3] };
            if [value.a, value.b, value.c, value.d].iter().any(|&x| x < 0 || x >= MODULUS) { return -1; }
            position += 4;
            if opcode == 0 { push_front(&mut front, &mut front_aggregates, &mut front_count, value); }
            else { push_back(&mut back, &mut back_aggregates, &mut back_count, value); }
        } else if opcode == 2 || opcode == 3 {
            if front_count + back_count == 0 { return -1; }
            if opcode == 2 {
                if front_count == 0 {
                    rebalance(&mut front, &mut front_aggregates, &mut front_count,
                              &mut back, &mut back_aggregates, &mut back_count, &mut temporary);
                }
                front_count -= 1;
            } else {
                if back_count == 0 {
                    rebalance(&mut front, &mut front_aggregates, &mut front_count,
                              &mut back, &mut back_aggregates, &mut back_count, &mut temporary);
                }
                back_count -= 1;
            }
        } else if opcode == 4 {
            let left = if front_count == 0 { IDENTITY } else { front_aggregates[front_count - 1] };
            let right = if back_count == 0 { IDENTITY } else { back_aggregates[back_count - 1] };
            query_ordinal += 1;
            checksum += query_ordinal * (pack(multiply(left, right)) + 1);
        } else { return -1; }
    }
    if position != length { return -1; }
    checksum
}
