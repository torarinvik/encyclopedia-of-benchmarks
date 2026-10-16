const MAX_COUNT: usize = 64;
const HEAP_CAPACITY: usize = 32;
const VALUE_LIMIT: i64 = 1_000_000;

fn heap_push(heap: &mut [i64; HEAP_CAPACITY], size: &mut usize, is_max: bool, value: i64) {
    let mut index = *size;
    *size += 1;
    heap[index] = value;
    while index > 0 {
        let parent = (index - 1) / 2;
        let ordered = if is_max { heap[parent] >= heap[index] } else { heap[parent] <= heap[index] };
        if ordered { break; }
        heap.swap(parent, index);
        index = parent;
    }
}

fn heap_pop(heap: &mut [i64; HEAP_CAPACITY], size: &mut usize, is_max: bool) -> i64 {
    let result = heap[0];
    *size -= 1;
    heap[0] = heap[*size];
    let mut index = 0;
    loop {
        let left = 2 * index + 1;
        let right = left + 1;
        let mut best = index;
        if left < *size && (if is_max { heap[left] > heap[best] } else { heap[left] < heap[best] }) { best = left; }
        if right < *size && (if is_max { heap[right] > heap[best] } else { heap[right] < heap[best] }) { best = right; }
        if best == index { break; }
        heap.swap(index, best);
        index = best;
    }
    result
}

unsafe fn write_f64_le(output: *mut u8, position: usize, value: f64) {
    for (byte, part) in value.to_bits().to_le_bytes().iter().enumerate() {
        *output.add(position + byte) = *part;
    }
}

#[no_mangle]
pub unsafe extern "C" fn median_finder(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_COUNT + 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    if !(1..=MAX_COUNT as i64).contains(&count_value) || length != count_value as usize + 1 { return -1; }
    let count = count_value as usize;
    if values[1..].iter().any(|value| !(-VALUE_LIMIT..=VALUE_LIMIT).contains(value)) { return -1; }
    let required = count * 8;
    if output.is_null() || output_capacity < required { return -2; }

    let mut lower = [0_i64; HEAP_CAPACITY];
    let mut upper = [0_i64; HEAP_CAPACITY];
    let mut lower_size = 0;
    let mut upper_size = 0;
    for (index, &value) in values[1..].iter().enumerate() {
        if lower_size == HEAP_CAPACITY && lower_size > upper_size && value <= lower[0] {
            heap_push(&mut upper, &mut upper_size, false, heap_pop(&mut lower, &mut lower_size, true));
            heap_push(&mut lower, &mut lower_size, true, value);
        } else {
            if lower_size == 0 || value <= lower[0] { heap_push(&mut lower, &mut lower_size, true, value); }
            else { heap_push(&mut upper, &mut upper_size, false, value); }
            if lower_size > upper_size + 1 { heap_push(&mut upper, &mut upper_size, false, heap_pop(&mut lower, &mut lower_size, true)); }
            else if upper_size > lower_size { heap_push(&mut lower, &mut lower_size, true, heap_pop(&mut upper, &mut upper_size, false)); }
        }
        let median = if lower_size == upper_size {
            (lower[0] as f64 + upper[0] as f64) / 2.0
        } else {
            lower[0] as f64
        };
        write_f64_le(output, index * 8, median);
    }
    required as i64
}
