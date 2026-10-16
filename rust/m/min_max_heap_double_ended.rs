const MAX_INITIAL: usize = 64;
const MAX_OPERATIONS: usize = 128;
const MAX_HEAP_SIZE: usize = MAX_INITIAL + MAX_OPERATIONS;
const INVALID_RESULT: i64 = -1;
const CAPACITY_RESULT: i64 = -2;

struct MinMaxHeap {
    values: [i32; MAX_HEAP_SIZE],
    count: usize,
}

impl MinMaxHeap {
    fn is_min_level(index: usize) -> bool {
        let mut value = index + 1;
        let mut depth = 0;
        while value > 1 { value >>= 1; depth += 1; }
        depth % 2 == 0
    }

    fn swap(&mut self, left: usize, right: usize) { self.values.swap(left, right); }

    fn best_descendant(&self, index: usize, find_min: bool) -> Option<usize> {
        let mut best = None;
        for offset in 0..6 {
            let candidate = if offset < 2 { 2 * index + 1 + offset } else { 4 * index + 1 + offset };
            if candidate >= self.count { break; }
            if best.map_or(true, |current| if find_min { self.values[candidate] < self.values[current] } else { self.values[candidate] > self.values[current] }) {
                best = Some(candidate);
            }
        }
        best
    }

    fn push_down(&mut self, mut index: usize, find_min: bool) {
        while index < self.count {
            let Some(best) = self.best_descendant(index, find_min) else { return; };
            let grandchild = best > 2 && (best - 3) / 4 == index;
            let improves = if find_min { self.values[best] < self.values[index] } else { self.values[best] > self.values[index] };
            if grandchild {
                if !improves { return; }
                self.swap(best, index);
                let parent = (best - 1) / 2;
                let violation = if find_min { self.values[best] > self.values[parent] } else { self.values[best] < self.values[parent] };
                if violation { self.swap(best, parent); }
                index = best;
            } else {
                if improves { self.swap(best, index); }
                return;
            }
        }
    }

    fn push_up_min(&mut self, mut index: usize) {
        while index > 2 {
            let gp = (index - 3) / 4;
            if self.values[index] >= self.values[gp] { return; }
            self.swap(index, gp);
            index = gp;
        }
    }

    fn push_up_max(&mut self, mut index: usize) {
        while index > 2 {
            let gp = (index - 3) / 4;
            if self.values[index] <= self.values[gp] { return; }
            self.swap(index, gp);
            index = gp;
        }
    }

    fn push_up(&mut self, index: usize) {
        if index == 0 { return; }
        let parent = (index - 1) / 2;
        if Self::is_min_level(index) {
            if self.values[index] > self.values[parent] {
                self.swap(index, parent);
                self.push_up_max(parent);
            } else { self.push_up_min(index); }
        } else if self.values[index] < self.values[parent] {
            self.swap(index, parent);
            self.push_up_min(parent);
        } else { self.push_up_max(index); }
    }

    fn add(&mut self, value: i32) {
        let index = self.count;
        self.count += 1;
        self.values[index] = value;
        self.push_up(index);
    }

    fn max_index(&self) -> usize {
        if self.count < 2 { 0 } else if self.count == 2 { 1 } else if self.values[1] > self.values[2] { 1 } else { 2 }
    }

    fn extract_at(&mut self, index: usize) -> i32 {
        let result = self.values[index];
        self.count -= 1;
        if index != self.count { self.values[index] = self.values[self.count]; }
        if self.count != 0 && index < self.count { self.push_down(index, Self::is_min_level(index)); }
        result
    }
}

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

fn insertion_sort(values: &mut [i32], count: usize) {
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
pub unsafe extern "C" fn min_max_heap_double_ended(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_INITIAL as i64).contains(&values[0]) { return INVALID_RESULT; }
    let initial_count = values[0] as usize;
    if length < initial_count + 2 { return INVALID_RESULT; }
    let operation_value = values[initial_count + 1];
    if !(0..=MAX_OPERATIONS as i64).contains(&operation_value) { return INVALID_RESULT; }
    let operation_count = operation_value as usize;
    if length != initial_count + 2 + 2 * operation_count { return INVALID_RESULT; }
    if values[1..initial_count + 1].iter().any(|v| *v < i32::MIN as i64 || *v > i32::MAX as i64) { return INVALID_RESULT; }
    for op in 0..operation_count {
        let opcode = values[initial_count + 2 + 2 * op];
        let argument = values[initial_count + 3 + 2 * op];
        if !(0..=5).contains(&opcode) { return INVALID_RESULT; }
        if opcode == 0 {
            if argument < i32::MIN as i64 || argument > i32::MAX as i64 { return INVALID_RESULT; }
        } else if argument != 0 { return INVALID_RESULT; }
    }

    let mut heap = MinMaxHeap { values: [0; MAX_HEAP_SIZE], count: initial_count };
    for index in 0..initial_count { heap.values[index] = values[index + 1] as i32; }
    for index in (0..initial_count / 2).rev() { heap.push_down(index, MinMaxHeap::is_min_level(index)); }
    let mut events = [0i64; MAX_OPERATIONS];
    let mut event_count = 0usize;
    for op in 0..operation_count {
        let opcode = values[initial_count + 2 + 2 * op];
        let argument = values[initial_count + 3 + 2 * op] as i32;
        match opcode {
            0 => heap.add(argument),
            1 | 3 => {
                if heap.count == 0 { return INVALID_RESULT; }
                events[event_count] = if opcode == 1 { heap.values[0] as i64 } else { heap.extract_at(0) as i64 };
                event_count += 1;
            }
            2 | 4 => {
                if heap.count == 0 { return INVALID_RESULT; }
                let index = heap.max_index();
                events[event_count] = if opcode == 2 { heap.values[index] as i64 } else { heap.extract_at(index) as i64 };
                event_count += 1;
            }
            _ => { events[event_count] = heap.count as i64; event_count += 1; }
        }
    }
    let mut sorted = heap.values;
    insertion_sort(&mut sorted, heap.count);
    let required = (2 + event_count + heap.count) * 8;
    if output.is_null() || capacity < required { return CAPACITY_RESULT; }
    let result = std::slice::from_raw_parts_mut(output, required);
    let mut offset = 0;
    write_i64_le(result, offset, event_count as i64); offset += 8;
    for value in events[..event_count].iter() { write_i64_le(result, offset, *value); offset += 8; }
    write_i64_le(result, offset, heap.count as i64); offset += 8;
    for value in sorted[..heap.count].iter() { write_i64_le(result, offset, *value as i64); offset += 8; }
    required as i64
}
