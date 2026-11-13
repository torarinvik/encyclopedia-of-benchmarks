const MAX_MACHINES: usize = 8;
const MAX_TASKS: usize = 32;
const MAX_PARSEABLE_WORDS: usize = 99;

fn eventLess(left: usize, right: usize, finish: *const [MAX_TASKS]i64) bool {
    if (finish[left] != finish[right]) return finish[left] < finish[right];
    return left < right;
}

fn heapPush(heap: *[MAX_TASKS]usize, size: *usize, task: usize,
             finish: *const [MAX_TASKS]i64) void {
    var position = size.*;
    size.* += 1;
    while (position > 0) {
        const parent = (position - 1) / 2;
        if (!eventLess(task, heap[parent], finish)) break;
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = task;
}

fn heapPop(heap: *[MAX_TASKS]usize, size: *usize,
            finish: *const [MAX_TASKS]i64) usize {
    const minimum = heap[0];
    size.* -= 1;
    if (size.* == 0) return minimum;
    const replacement = heap[size.*];
    var position: usize = 0;
    while (true) {
        const left = 2 * position + 1;
        if (left >= size.*) break;
        const right = left + 1;
        var child = left;
        if (right < size.* and eventLess(heap[right], heap[left], finish)) child = right;
        if (!eventLess(heap[child], replacement, finish)) break;
        heap[position] = heap[child];
        position = child;
    }
    heap[position] = replacement;
    return minimum;
}

export fn online_temporary_task_load_balancing(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_WORDS) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_MACHINES)) or
        input[1] < 0 or input[1] > @as(i64, @intCast(MAX_TASKS))) return -1;
    const machine_count: usize = @intCast(input[0]);
    const task_count: usize = @intCast(input[1]);
    if (length != 2 + 3 * task_count) return -1;

    var arrivals = [_]i64{0} ** MAX_TASKS;
    var weights = [_]i64{0} ** MAX_TASKS;
    var finish = [_]i64{0} ** MAX_TASKS;
    var assigned = [_]usize{0} ** MAX_TASKS;
    var loads = [_]i64{0} ** MAX_MACHINES;
    var heap = [_]usize{0} ** MAX_TASKS;
    var heap_size: usize = 0;
    var staged = [_]i64{0} ** (MAX_TASKS + 1);
    var previous_arrival: i64 = -1;
    for (0..task_count) |task| {
        const at = input[2 + 3 * task];
        const amount = input[3 + 3 * task];
        const duration = input[4 + 3 * task];
        if (at < 0 or at > 1000 or at < previous_arrival or amount < 1 or amount > 1000 or
            duration < 1 or duration > 1000 or at + duration > 2000) return -1;
        arrivals[task] = at;
        weights[task] = amount;
        finish[task] = at + duration;
        previous_arrival = at;
    }

    var peak: i64 = 0;
    for (0..task_count) |task| {
        while (heap_size > 0 and finish[heap[0]] <= arrivals[task]) {
            const expired = heapPop(&heap, &heap_size, &finish);
            loads[assigned[expired]] -= weights[expired];
        }
        var machine: usize = 0;
        for (1..machine_count) |candidate| {
            if (loads[candidate] < loads[machine]) machine = candidate;
        }
        assigned[task] = machine;
        loads[machine] += weights[task];
        if (loads[machine] > peak) peak = loads[machine];
        heapPush(&heap, &heap_size, task, &finish);
    }

    staged[0] = peak;
    for (0..task_count) |task| staged[task + 1] = @intCast(assigned[task]);
    const output_words = task_count + 1;
    const output_bytes = 8 * output_words;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    for (0..output_words) |word| {
        const bits: u64 = @intCast(staged[word]);
        for (0..8) |byte| {
            output[8 * word + byte] = @truncate(bits >> @as(u6, @intCast(8 * byte)));
        }
    }
    return @intCast(output_bytes);
}
