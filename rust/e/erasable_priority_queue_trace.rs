const MAX_Q: usize = 63;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 128;
const VALUE_OFFSET: i64 = 100;
const VALUE_COUNT: usize = 201;

fn entry_less(left: usize, right: usize, values: &[i64; MAX_Q]) -> bool {
    values[left] < values[right] || (values[left] == values[right] && left < right)
}

fn heap_push(
    heap: &mut [usize; MAX_Q],
    size: &mut usize,
    item: usize,
    values: &[i64; MAX_Q],
) {
    let mut at = *size;
    *size += 1;
    while at > 0 {
        let parent = (at - 1) / 2;
        if !entry_less(item, heap[parent], values) {
            break;
        }
        heap[at] = heap[parent];
        at = parent;
    }
    heap[at] = item;
}

fn heap_pop(
    heap: &mut [usize; MAX_Q],
    size: &mut usize,
    values: &[i64; MAX_Q],
) -> usize {
    let result = heap[0];
    *size -= 1;
    if *size == 0 {
        return result;
    }
    let last = heap[*size];
    let mut at = 0usize;
    loop {
        let mut child = 2 * at + 1;
        if child >= *size {
            break;
        }
        if child + 1 < *size && entry_less(heap[child + 1], heap[child], values) {
            child += 1;
        }
        if !entry_less(heap[child], last, values) {
            break;
        }
        heap[at] = heap[child];
        at = child;
    }
    heap[at] = last;
    result
}

fn normalize(
    live: &mut [usize; MAX_Q],
    live_size: &mut usize,
    deleted: &mut [usize; MAX_Q],
    deleted_size: &mut usize,
    values: &[i64; MAX_Q],
) {
    while *live_size > 0 && *deleted_size > 0 && live[0] == deleted[0] {
        heap_pop(live, live_size, values);
        heap_pop(deleted, deleted_size, values);
    }
}

#[no_mangle]
pub unsafe extern "C" fn erasable_priority_queue_trace(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let words = std::slice::from_raw_parts(input, length);
    if words[0] < 0 || words[0] > MAX_Q as i64 {
        return -1;
    }
    let operation_count = words[0] as usize;
    if length != 1 + 2 * operation_count {
        return -1;
    }

    let mut values = [0i64; MAX_Q];
    let mut counts = [0usize; VALUE_COUNT];
    let mut active = [false; MAX_Q];
    let mut live = [0usize; MAX_Q];
    let mut deleted = [0usize; MAX_Q];
    let mut live_size = 0usize;
    let mut deleted_size = 0usize;
    let mut inserted = 0usize;
    let mut score = 0i64;

    for operation in 0..operation_count {
        let opcode_value = words[1 + 2 * operation];
        let operand_value = words[2 + 2 * operation];
        if !(0..=3).contains(&opcode_value)
            || operand_value < -VALUE_OFFSET
            || operand_value > VALUE_OFFSET
        {
            return -1;
        }
        let opcode = opcode_value as usize;
        let operand = operand_value as i32;
        normalize(&mut live, &mut live_size, &mut deleted, &mut deleted_size, &values);

        let response: i64;
        if opcode == 0 {
            let id = inserted;
            inserted += 1;
            values[id] = operand_value;
            active[id] = true;
            counts[(operand + VALUE_OFFSET as i32) as usize] += 1;
            heap_push(&mut live, &mut live_size, id, &values);
            normalize(&mut live, &mut live_size, &mut deleted, &mut deleted_size, &values);
            response = 0;
        } else if opcode == 1 {
            let key = (operand + VALUE_OFFSET as i32) as usize;
            if counts[key] == 0 {
                return -1;
            }
            let mut found = None;
            for candidate in 0..inserted {
                if active[candidate] && values[candidate] == operand_value {
                    found = Some(candidate);
                    break;
                }
            }
            let Some(id) = found else {
                return -1;
            };
            active[id] = false;
            counts[key] -= 1;
            heap_push(&mut deleted, &mut deleted_size, id, &values);
            normalize(&mut live, &mut live_size, &mut deleted, &mut deleted_size, &values);
            response = 1;
        } else if opcode == 2 {
            if operand_value != 0 {
                return -1;
            }
            response = if live_size == 0 { -101 } else { values[live[0]] };
        } else {
            if operand_value != 0 || live_size == 0 {
                return -1;
            }
            let id = heap_pop(&mut live, &mut live_size, &values);
            active[id] = false;
            counts[(values[id] as i32 + VALUE_OFFSET as i32) as usize] -= 1;
            response = values[id];
        }

        let token = opcode_value * 202 + response + 101;
        score += (operation as i64 + 1) * token;
    }
    score
}
