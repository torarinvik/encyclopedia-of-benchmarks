const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MAX_INPUT_LENGTH: usize = 258;

#[derive(Clone, Copy)]
struct Query {
    left: usize,
    right: usize,
    time: usize,
    ordinal: usize,
}

#[derive(Clone, Copy)]
struct Change {
    position: usize,
    before_value: usize,
    after_value: usize,
}

struct Window {
    values: [usize; MAX_N],
    frequencies: [usize; 16],
    distinct_count: usize,
    left: i32,
    right: i32,
}

impl Window {
    fn new(values: [usize; MAX_N]) -> Self {
        Self { values, frequencies: [0; 16], distinct_count: 0, left: 0, right: -1 }
    }
    fn add(&mut self, position: usize) {
        let value = self.values[position];
        if self.frequencies[value] == 0 { self.distinct_count += 1; }
        self.frequencies[value] += 1;
    }
    fn remove(&mut self, position: usize) {
        let value = self.values[position];
        self.frequencies[value] -= 1;
        if self.frequencies[value] == 0 { self.distinct_count -= 1; }
    }
    fn replace(&mut self, position: usize, new_value: usize) {
        let active = position as i32 >= self.left && position as i32 <= self.right;
        if active { self.remove(position); }
        self.values[position] = new_value;
        if active { self.add(position); }
    }
}

fn query_before(a: Query, b: Query, block_size: usize) -> bool {
    let left_block_a = a.left / block_size;
    let left_block_b = b.left / block_size;
    if left_block_a != left_block_b { return left_block_a < left_block_b; }
    let right_block_a = a.right / block_size;
    let right_block_b = b.right / block_size;
    if right_block_a != right_block_b { return right_block_a < right_block_b; }
    if a.time != b.time { return a.time < b.time; }
    a.ordinal < b.ordinal
}

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.len() < 2 || input.len() > MAX_INPUT_LENGTH { return Err(()); }
    let (n64, q64) = (input[0], input[1]);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_Q as i64).contains(&q64)
        || input.len() != 2 + n64 as usize + 3 * q64 as usize { return Err(()); }
    let (n, q) = (n64 as usize, q64 as usize);

    let mut initial = [0usize; MAX_N];
    for i in 0..n {
        if !(0..=15).contains(&input[2 + i]) { return Err(()); }
        initial[i] = input[2 + i] as usize;
    }
    let operation_offset = 2 + n;
    for i in 0..q {
        let op = input[operation_offset + 3 * i];
        let first = input[operation_offset + 3 * i + 1];
        let second = input[operation_offset + 3 * i + 2];
        if op == 0 {
            if first < 0 || first >= n64 || !(0..=15).contains(&second) { return Err(()); }
        } else if op == 1 {
            if first < 0 || second < first || second >= n64 { return Err(()); }
        } else { return Err(()); }
    }

    let mut parse_state = initial;
    let mut changes = [Change { position: 0, before_value: 0, after_value: 0 }; MAX_Q];
    let mut queries = [Query { left: 0, right: 0, time: 0, ordinal: 0 }; MAX_Q];
    let (mut change_count, mut query_count) = (0usize, 0usize);
    for i in 0..q {
        let op = input[operation_offset + 3 * i];
        let first = input[operation_offset + 3 * i + 1] as usize;
        let second = input[operation_offset + 3 * i + 2] as usize;
        if op == 0 {
            changes[change_count] = Change { position: first, before_value: parse_state[first], after_value: second };
            parse_state[first] = second;
            change_count += 1;
        } else {
            queries[query_count] = Query { left: first, right: second, time: change_count, ordinal: query_count };
            query_count += 1;
        }
    }

    let mut block_size = 1usize;
    while (block_size + 1) * (block_size + 1) * (block_size + 1) <= n * n { block_size += 1; }
    for i in 1..query_count {
        let current = queries[i];
        let mut position = i;
        while position > 0 && query_before(current, queries[position - 1], block_size) {
            queries[position] = queries[position - 1];
            position -= 1;
        }
        queries[position] = current;
    }

    let mut window = Window::new(initial);
    let mut current_time = 0usize;
    let mut answers = [0usize; MAX_Q];
    for query in queries.iter().take(query_count) {
        while current_time < query.time {
            let change = changes[current_time];
            window.replace(change.position, change.after_value);
            current_time += 1;
        }
        while current_time > query.time {
            current_time -= 1;
            let change = changes[current_time];
            window.replace(change.position, change.before_value);
        }
        while window.left > query.left as i32 {
            window.left -= 1;
            let position = window.left as usize;
            window.add(position);
        }
        while window.right < query.right as i32 {
            window.right += 1;
            let position = window.right as usize;
            window.add(position);
        }
        while window.left < query.left as i32 { window.remove(window.left as usize); window.left += 1; }
        while window.right > query.right as i32 { window.remove(window.right as usize); window.right -= 1; }
        answers[query.ordinal] = window.distinct_count;
    }

    let mut checksum = 0i64;
    for ordinal in 0..query_count { checksum += (ordinal as i64 + 1) * (answers[ordinal] as i64 + 1); }
    Ok(checksum)
}

#[no_mangle]
pub unsafe extern "C" fn mo_with_modifications(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
