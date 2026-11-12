const MAX_MACHINES: usize = 8;
const MAX_TASKS: usize = 32;
const MAX_PARSEABLE_WORDS: usize = 99;

fn event_less(left: usize, right: usize, finish: &[i64; MAX_TASKS]) -> bool {
    if finish[left] != finish[right] { finish[left] < finish[right] } else { left < right }
}

fn heap_push(heap: &mut [usize; MAX_TASKS], size: &mut usize, task: usize,
              finish: &[i64; MAX_TASKS]) {
    let mut position = *size;
    *size += 1;
    while position > 0 {
        let parent = (position - 1) / 2;
        if !event_less(task, heap[parent], finish) { break; }
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = task;
}

fn heap_pop(heap: &mut [usize; MAX_TASKS], size: &mut usize,
            finish: &[i64; MAX_TASKS]) -> usize {
    let minimum = heap[0];
    *size -= 1;
    if *size == 0 { return minimum; }
    let replacement = heap[*size];
    let mut position = 0;
    loop {
        let left = 2 * position + 1;
        if left >= *size { break; }
        let right = left + 1;
        let mut child = left;
        if right < *size && event_less(heap[right], heap[left], finish) { child = right; }
        if !event_less(heap[child], replacement, finish) { break; }
        heap[position] = heap[child];
        position = child;
    }
    heap[position] = replacement;
    minimum
}

#[no_mangle]
pub unsafe extern "C" fn online_temporary_task_load_balancing(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_WORDS { return -1; }
    let machine_value = *input;
    let task_value = *input.add(1);
    if machine_value < 1 || machine_value > MAX_MACHINES as i64 || task_value < 0 || task_value > MAX_TASKS as i64 { return -1; }
    let machine_count = machine_value as usize;
    let task_count = task_value as usize;
    if length != 2 + 3 * task_count { return -1; }

    let mut arrival = [0_i64; MAX_TASKS];
    let mut weight = [0_i64; MAX_TASKS];
    let mut finish = [0_i64; MAX_TASKS];
    let mut assigned = [0_usize; MAX_TASKS];
    let mut loads = [0_i64; MAX_MACHINES];
    let mut heap = [0_usize; MAX_TASKS];
    let mut heap_size = 0_usize;
    let mut staged = [0_i64; MAX_TASKS + 1];
    let mut previous_arrival = -1_i64;

    for task in 0..task_count {
        let at = *input.add(2 + 3 * task);
        let amount = *input.add(3 + 3 * task);
        let duration = *input.add(4 + 3 * task);
        if at < 0 || at > 1000 || at < previous_arrival || amount < 1 || amount > 1000 ||
            duration < 1 || duration > 1000 || at + duration > 2000 { return -1; }
        arrival[task] = at;
        weight[task] = amount;
        finish[task] = at + duration;
        previous_arrival = at;
    }

    let mut peak = 0_i64;
    for task in 0..task_count {
        while heap_size > 0 && finish[heap[0]] <= arrival[task] {
            let expired = heap_pop(&mut heap, &mut heap_size, &finish);
            loads[assigned[expired]] -= weight[expired];
        }
        let mut machine = 0_usize;
        for candidate in 1..machine_count {
            if loads[candidate] < loads[machine] { machine = candidate; }
        }
        assigned[task] = machine;
        loads[machine] += weight[task];
        if loads[machine] > peak { peak = loads[machine]; }
        heap_push(&mut heap, &mut heap_size, task, &finish);
    }

    staged[0] = peak;
    for task in 0..task_count { staged[task + 1] = assigned[task] as i64; }
    let output_words = task_count + 1;
    let output_bytes = 8 * output_words;
    if output.is_null() || capacity < output_bytes { return -2; }
    for word in 0..output_words {
        let bits = staged[word] as u64;
        for byte in 0..8 { *output.add(8 * word + byte) = ((bits >> (8 * byte)) & 255) as u8; }
    }
    output_bytes as i64
}
