const MAX_INPUT_VALUES: usize = 227;
const MAX_NODES: usize = 96;
const MAX_OUTPUT_BYTES: usize = 1808;

struct List {
    values: [i64; MAX_NODES],
    next: [i32; MAX_NODES],
    used: usize,
    head: i32,
    tail: i32,
    length: usize,
}

impl List {
    fn new() -> Self {
        Self { values: [0; MAX_NODES], next: [-1; MAX_NODES], used: 0, head: -1, tail: -1, length: 0 }
    }

    fn allocate(&mut self, value: i64) -> i32 {
        let node = self.used;
        self.used += 1;
        self.values[node] = value;
        self.next[node] = -1;
        node as i32
    }

    fn add_head(&mut self, value: i64) {
        let node = self.allocate(value);
        self.next[node as usize] = self.head;
        if self.head < 0 { self.tail = node; }
        self.head = node;
        self.length += 1;
    }

    fn add_tail(&mut self, value: i64) {
        let node = self.allocate(value);
        if self.tail < 0 { self.head = node; }
        else { self.next[self.tail as usize] = node; }
        self.tail = node;
        self.length += 1;
    }

    fn delete_head(&mut self) -> Option<i64> {
        if self.head < 0 { return None; }
        let node = self.head as usize;
        let value = self.values[node];
        self.head = self.next[node];
        self.length -= 1;
        if self.length == 0 { self.tail = -1; }
        Some(value)
    }

    fn delete_tail(&mut self) -> Option<i64> {
        if self.tail < 0 { return None; }
        let old_tail = self.tail as usize;
        let value = self.values[old_tail];
        if self.length == 1 {
            self.head = -1;
            self.tail = -1;
        } else {
            let mut previous = self.head as usize;
            while self.next[previous] != self.tail { previous = self.next[previous] as usize; }
            self.next[previous] = -1;
            self.tail = previous as i32;
        }
        self.length -= 1;
        Some(value)
    }

    fn delete_position(&mut self, position: usize) -> Option<i64> {
        if self.length == 0 { return None; }
        if position == 1 { return self.delete_head(); }
        if position >= self.length { return self.delete_tail(); }
        let mut previous = self.head as usize;
        for _ in 1..position - 1 { previous = self.next[previous] as usize; }
        let node = self.next[previous] as usize;
        self.next[previous] = self.next[node];
        self.length -= 1;
        Some(self.values[node])
    }

    fn reverse(&mut self) {
        let mut previous = -1_i32;
        let mut current = self.head;
        self.tail = self.head;
        while current >= 0 {
            let node = current as usize;
            let following = self.next[node];
            self.next[node] = previous;
            previous = current;
            current = following;
        }
        self.head = previous;
    }

    fn reverse_range(&mut self, left: usize, right: usize) {
        let mut before = -1_i32;
        let mut start = self.head;
        for _ in 1..left { before = start; start = self.next[start as usize]; }
        let mut previous = -1_i32;
        let mut current = start;
        for _ in left..=right {
            let node = current as usize;
            let following = self.next[node];
            self.next[node] = previous;
            previous = current;
            current = following;
        }
        self.next[start as usize] = current;
        if before < 0 { self.head = previous; }
        else { self.next[before as usize] = previous; }
        if right == self.length { self.tail = start; }
    }
}

unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (byte * 8)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn singlylinkedlist(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let initial_count_value = *input;
    let operation_count_value = *input.add(1);
    if !(0..=32).contains(&initial_count_value) || !(0..=64).contains(&operation_count_value) { return -1; }
    let initial_count = initial_count_value as usize;
    let operation_count = operation_count_value as usize;
    if length < 2 + initial_count { return -1; }
    let mut list = List::new();
    for i in 0..initial_count {
        let value = *input.add(2 + i);
        if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
        list.add_tail(value);
    }
    let mut results = [0_i64; 128];
    let mut cursor = 2 + initial_count;
    for operation in 0..operation_count {
        if cursor >= length { return -1; }
        let opcode = *input.add(cursor);
        cursor += 1;
        let mut arg1 = 0_i64;
        let mut arg2 = 0_i64;
        if opcode == 0 || opcode == 1 || opcode == 4 { if cursor >= length { return -1; } arg1 = *input.add(cursor); cursor += 1; }
        else if opcode == 6 { if length - cursor < 2 { return -1; } arg1 = *input.add(cursor); arg2 = *input.add(cursor + 1); cursor += 2; }
        else if opcode != 2 && opcode != 3 && opcode != 5 { return -1; }

        let (success, value) = match opcode {
            0 | 1 => {
                if !(-1_000_000..=1_000_000).contains(&arg1) { return -1; }
                if opcode == 0 { list.add_head(arg1); } else { list.add_tail(arg1); }
                (1, 0)
            }
            2 => match list.delete_head() { Some(value) => (1, value), None => (0, 0) },
            3 => match list.delete_tail() { Some(value) => (1, value), None => (0, 0) },
            4 => {
                if list.length == 0 {
                    if arg1 != 1 { return -1; }
                    (0, 0)
                } else {
                    if arg1 < 1 || arg1 as usize > list.length + 1 { return -1; }
                    match list.delete_position(arg1 as usize) { Some(value) => (1, value), None => (0, 0) }
                }
            }
            5 => { list.reverse(); (1, 0) }
            _ => {
                if arg1 < 1 || arg2 < arg1 || arg2 as usize > list.length { return -1; }
                list.reverse_range(arg1 as usize, arg2 as usize);
                (1, 0)
            }
        };
        results[operation * 2] = success;
        results[operation * 2 + 1] = value;
    }
    if cursor != length { return -1; }
    let output_values = 1 + list.length + 1 + operation_count * 2;
    let output_bytes = output_values * 8;
    if output_bytes > MAX_OUTPUT_BYTES { return -1; }
    if output.is_null() || capacity < output_bytes { return -2; }
    put_i64_le(output, 0, list.length as i64);
    let mut offset = 8;
    let mut node = list.head;
    while node >= 0 {
        let index = node as usize;
        put_i64_le(output, offset, list.values[index]);
        offset += 8;
        node = list.next[index];
    }
    put_i64_le(output, offset, operation_count as i64);
    offset += 8;
    for value in results.iter().take(operation_count * 2) { put_i64_le(output, offset, *value); offset += 8; }
    output_bytes as i64
}
