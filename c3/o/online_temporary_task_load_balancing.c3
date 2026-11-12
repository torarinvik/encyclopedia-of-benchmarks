module online_temporary_task_load_balancing;

const MAX_MACHINES = 8;
const MAX_TASKS = 32;
const MAX_PARSEABLE_WORDS = 99;

fn bool event_less(usz left, usz right, long* finish) {
    return finish[left] < finish[right] || (finish[left] == finish[right] && left < right);
}

fn void heap_push(usz* heap, usz* size, usz task, long* finish) {
    usz position = *size;
    *size += 1;
    while (position > 0) {
        usz parent = (position - 1) / 2;
        if (!event_less(task, heap[parent], finish)) break;
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = task;
}

fn usz heap_pop(usz* heap, usz* size, long* finish) {
    usz minimum = heap[0];
    *size -= 1;
    if (*size == 0) return minimum;
    usz replacement = heap[*size];
    usz position = 0;
    while (true) {
        usz left = 2 * position + 1;
        if (left >= *size) break;
        usz right = left + 1;
        usz child = left;
        if (right < *size && event_less(heap[right], heap[left], finish)) child = right;
        if (!event_less(heap[child], replacement, finish)) break;
        heap[position] = heap[child];
        position = child;
    }
    heap[position] = replacement;
    return minimum;
}

fn void write_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long online_temporary_task_load_balancing(long* input, usz length,
        char* output, usz capacity) @export("online_temporary_task_load_balancing") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_WORDS) return -1;
    long machine_value = input[0], task_value = input[1];
    if (machine_value < 1 || machine_value > MAX_MACHINES || task_value < 0 || task_value > MAX_TASKS) return -1;
    usz machine_count = (usz)machine_value, task_count = (usz)task_value;
    if (length != 2 + 3 * task_count) return -1;

    long[MAX_TASKS] arrival, weight, finish;
    usz[MAX_TASKS] assigned, heap;
    long[MAX_MACHINES] loads;
    long[MAX_TASKS + 1] staged;
    usz heap_size = 0;
    long previous_arrival = -1;
    for (usz task = 0; task < task_count; task++) {
        long at = input[2 + 3 * task];
        long amount = input[3 + 3 * task];
        long duration = input[4 + 3 * task];
        if (at < 0 || at > 1000 || at < previous_arrival || amount < 1 || amount > 1000 ||
            duration < 1 || duration > 1000 || at + duration > 2000) return -1;
        arrival[task] = at;
        weight[task] = amount;
        finish[task] = at + duration;
        previous_arrival = at;
    }

    long peak = 0;
    for (usz task = 0; task < task_count; task++) {
        while (heap_size > 0 && finish[heap[0]] <= arrival[task]) {
            usz expired = heap_pop(&heap[0], &heap_size, &finish[0]);
            loads[assigned[expired]] -= weight[expired];
        }
        usz machine = 0;
        for (usz candidate = 1; candidate < machine_count; candidate++)
            if (loads[candidate] < loads[machine]) machine = candidate;
        assigned[task] = machine;
        loads[machine] += weight[task];
        if (loads[machine] > peak) peak = loads[machine];
        heap_push(&heap[0], &heap_size, task, &finish[0]);
    }
    staged[0] = peak;
    for (usz task = 0; task < task_count; task++) staged[task + 1] = (long)assigned[task];
    usz output_words = task_count + 1, output_bytes = 8 * output_words;
    if (output == null || capacity < output_bytes) return -2;
    for (usz word = 0; word < output_words; word++) write_i64(&output[0], 8 * word, staged[word]);
    return (long)output_bytes;
}
