const MAX_INITIAL: usize = 64;
const MAX_OPERATIONS: usize = 128;
const MAX_KEYS: usize = MAX_INITIAL + MAX_OPERATIONS;
const MAX_INPUT: usize = MAX_INITIAL + 2 + 2 * MAX_OPERATIONS;

struct IntervalHeap {
    keys: [i32; MAX_KEYS],
    count: usize,
}

impl IntervalHeap {
    fn high_index(&self, node: usize) -> usize {
        let high = 2 * node + 1;
        if high < self.count { high } else { 2 * node }
    }

    fn sift_up_low(&mut self, mut node: usize) {
        while node > 0 {
            let parent = (node - 1) / 2;
            let low = 2 * node;
            let parent_low = 2 * parent;
            if self.keys[low] >= self.keys[parent_low] { return; }
            self.keys.swap(low, parent_low);
            node = parent;
        }
    }

    fn sift_up_high(&mut self, mut node: usize) {
        while node > 0 {
            let parent = (node - 1) / 2;
            let high = self.high_index(node);
            let parent_high = self.high_index(parent);
            if self.keys[high] <= self.keys[parent_high] { return; }
            self.keys.swap(high, parent_high);
            node = parent;
        }
    }

    fn insert(&mut self, value: i32) {
        let key_index = self.count;
        self.keys[key_index] = value;
        self.count += 1;
        let node = key_index / 2;
        if key_index % 2 == 1 && self.keys[key_index] < self.keys[key_index - 1] {
            self.keys.swap(key_index, key_index - 1);
        }
        self.sift_up_low(node);
        self.sift_up_high(node);
    }

    fn extract_min(&mut self) -> i32 {
        let result = self.keys[0];
        self.count -= 1;
        let last = self.keys[self.count];
        if self.count == 0 { return result; }
        self.keys[0] = last;
        let mut node = 0;
        loop {
            let left = 2 * node + 1;
            if 2 * left >= self.count { return result; }
            let right = left + 1;
            let mut child = left;
            if 2 * right < self.count && self.keys[2 * right] < self.keys[2 * left] { child = right; }
            let node_low = 2 * node;
            let child_low = 2 * child;
            if self.keys[child_low] >= self.keys[node_low] { return result; }
            self.keys.swap(node_low, child_low);
            let child_high = self.high_index(child);
            if self.keys[child_high] < self.keys[child_low] { self.keys.swap(child_high, child_low); }
            node = child;
        }
    }

    fn extract_max(&mut self) -> i32 {
        if self.count <= 2 {
            self.count -= 1;
            return self.keys[self.count];
        }
        let result = self.keys[1];
        self.count -= 1;
        self.keys[1] = self.keys[self.count];
        let mut node = 0;
        loop {
            let left = 2 * node + 1;
            if 2 * left >= self.count { return result; }
            let right = left + 1;
            let mut child = left;
            if 2 * right < self.count && self.keys[self.high_index(left)] < self.keys[self.high_index(right)] { child = right; }
            let node_high = self.high_index(node);
            let child_high = self.high_index(child);
            if self.keys[node_high] >= self.keys[child_high] { return result; }
            self.keys.swap(node_high, child_high);
            let child_low = 2 * child;
            if self.keys[child_high] < self.keys[child_low] { self.keys.swap(child_high, child_low); }
            node = child;
        }
    }
}

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

fn sort_i32(values: &mut [i32], count: usize) {
    for index in 1..count {
        let value = values[index];
        let mut position = index;
        while position > 0 && values[position - 1] > value {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = value;
    }
}

#[no_mangle]
pub unsafe extern "C" fn interval_heap_double_ended(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_INITIAL as i64).contains(&values[0]) { return -1; }
    let initial_count = values[0] as usize;
    if length < initial_count + 2 { return -1; }
    if !(0..=MAX_OPERATIONS as i64).contains(&values[initial_count + 1]) { return -1; }
    let operation_count = values[initial_count + 1] as usize;
    if length != initial_count + 2 + 2 * operation_count { return -1; }
    if values[1..initial_count + 1].iter().any(|value| *value < i32::MIN as i64 || *value > i32::MAX as i64) { return -1; }
    for op in 0..operation_count {
        let opcode = values[initial_count + 2 + 2 * op];
        let argument = values[initial_count + 3 + 2 * op];
        if !(0..=5).contains(&opcode) { return -1; }
        if opcode == 0 {
            if argument < i32::MIN as i64 || argument > i32::MAX as i64 { return -1; }
        } else if argument != 0 { return -1; }
    }

    let mut heap = IntervalHeap { keys: [0; MAX_KEYS], count: 0 };
    for value in &values[1..initial_count + 1] { heap.insert(*value as i32); }
    let mut events = [0i64; MAX_OPERATIONS];
    let mut event_count = 0usize;
    for op in 0..operation_count {
        let opcode = values[initial_count + 2 + 2 * op];
        let argument = values[initial_count + 3 + 2 * op] as i32;
        match opcode {
            0 => heap.insert(argument),
            1 => { if heap.count == 0 { return -1; } events[event_count] = heap.keys[0] as i64; event_count += 1; },
            2 => { if heap.count == 0 { return -1; } events[event_count] = heap.keys[heap.high_index(0)] as i64; event_count += 1; },
            3 => { if heap.count == 0 { return -1; } events[event_count] = heap.extract_min() as i64; event_count += 1; },
            4 => { if heap.count == 0 { return -1; } events[event_count] = heap.extract_max() as i64; event_count += 1; },
            _ => { events[event_count] = heap.count as i64; event_count += 1; },
        }
    }
    let mut sorted = heap.keys;
    sort_i32(&mut sorted, heap.count);
    let required = (2 + event_count + heap.count) * 8;
    if output.is_null() || capacity < required { return -2; }
    let out = std::slice::from_raw_parts_mut(output, required);
    let mut offset = 0;
    write_i64_le(out, offset, event_count as i64); offset += 8;
    for value in events[..event_count].iter() { write_i64_le(out, offset, *value); offset += 8; }
    write_i64_le(out, offset, heap.count as i64); offset += 8;
    for value in sorted[..heap.count].iter() { write_i64_le(out, offset, *value as i64); offset += 8; }
    required as i64
}
