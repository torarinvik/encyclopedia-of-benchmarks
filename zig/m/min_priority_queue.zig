const MAX_CAPACITY: usize = 64;
const MAX_OPS: usize = 64;
const MAX_INPUT_LENGTH: usize = 130;
const MAX_OUTPUT_WORDS: usize = 1 + 2 * MAX_OPS;

fn putI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn min_priority_queue(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_CAPACITY)) or
        input[1] < 0 or input[1] > @as(i64, @intCast(MAX_OPS))) return -1;

    const capacity: usize = @intCast(input[0]);
    const operation_count: usize = @intCast(input[1]);
    var heap: [MAX_CAPACITY]i32 = [_]i32{0} ** MAX_CAPACITY;
    var words: [MAX_OUTPUT_WORDS]i32 = undefined;
    var heap_size: usize = 0;
    var word_count: usize = 1;
    var query_count: usize = 0;
    var pos: usize = 2;

    for (0..operation_count) |_| {
        if (pos >= length) return -1;
        const opcode = input[pos];
        pos += 1;
        if (opcode == 0) {
            if (pos >= length) return -1;
            const raw = input[pos];
            pos += 1;
            if (raw < -2147483648 or raw > 2147483647 or heap_size >= capacity) return -1;
            var index = heap_size;
            heap[index] = @intCast(raw);
            while (index > 0) {
                const parent = (index - 1) / 2;
                if (heap[parent] <= heap[index]) break;
                const tmp = heap[parent];
                heap[parent] = heap[index];
                heap[index] = tmp;
                index = parent;
            }
            heap_size += 1;
        } else if (opcode == 1 or opcode == 2) {
            if (heap_size == 0) return -1;
            const value = heap[0];
            if (opcode == 2) {
                heap_size -= 1;
                if (heap_size > 0) {
                    heap[0] = heap[heap_size];
                    var index: usize = 0;
                    while (true) {
                        const left = 2 * index + 1;
                        if (left >= heap_size) break;
                        const right = left + 1;
                        var child = left;
                        if (right < heap_size and heap[right] < heap[left]) child = right;
                        if (heap[index] <= heap[child]) break;
                        const tmp = heap[index];
                        heap[index] = heap[child];
                        heap[child] = tmp;
                        index = child;
                    }
                }
            }
            words[word_count] = if (opcode == 1) 1 else 2;
            words[word_count + 1] = value;
            word_count += 2;
            query_count += 1;
        } else if (opcode == 3 or opcode == 4) {
            words[word_count] = if (opcode == 3) 3 else 4;
            words[word_count + 1] = if (opcode == 3)
                (if (heap_size == 0) 1 else 0)
            else if (heap_size == capacity) 1 else 0;
            word_count += 2;
            query_count += 1;
        } else return -1;
    }

    if (pos != length or word_count > MAX_OUTPUT_WORDS) return -1;
    words[0] = @intCast(query_count);
    const bytes = word_count * 4;
    if (output_opt == null or output_capacity < bytes) return -2;
    const output = output_opt.?;
    var buffer: [MAX_OUTPUT_WORDS * 4]u8 = undefined;
    for (0..word_count) |i| putI32Le(&buffer, i * 4, words[i]);
    for (0..bytes) |i| output[i] = buffer[i];
    return @intCast(bytes);
}
