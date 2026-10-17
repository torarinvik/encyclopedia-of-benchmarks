const MAX_CAPACITY: usize = 128;
const MAX_CAPACITY_VALUE: i64 = 128;
const MAX_OPERATIONS: i64 = 256;
const MAX_INPUT_VALUES: usize = 515;
const MAX_OUTPUT_BYTES: usize = 4096;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
    }
}

export fn priority_queues(input: [*c]const i64, length: usize,
                          output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    if (input[0] < 1 or input[0] > MAX_CAPACITY_VALUE or
        input[1] < 0 or input[1] > MAX_OPERATIONS) return -1;

    const capacity: usize = @intCast(input[0]);
    const operation_count: usize = @intCast(input[1]);
    if (length != 2 + 2 * operation_count) return -1;
    for (0..operation_count) |operation| {
        const opcode = input[2 + 2 * operation];
        const argument = input[3 + 2 * operation];
        if (opcode < 0 or opcode > 5) return -1;
        if (opcode == 0) {
            if (argument < -2_147_483_648 or argument > 2_147_483_647) return -1;
        } else if (argument != 0) {
            return -1;
        }
    }

    if (operation_count == 0) return 0;
    const needed = operation_count * 16;
    if (needed > MAX_OUTPUT_BYTES or output == null or output_capacity < needed) return -2;

    var heap: [MAX_CAPACITY + 1]i32 = @splat(0);
    var size: usize = 0;
    for (0..operation_count) |operation| {
        const opcode = input[2 + 2 * operation];
        const argument = input[3 + 2 * operation];
        var status: i64 = 0;
        var value: i64 = 0;

        if (opcode == 0) {
            if (size == capacity) {
                status = 1;
            } else {
                size += 1;
                heap[size] = @intCast(argument);
                var index = size;
                while (index > 1 and heap[index / 2] < heap[index]) {
                    const temporary = heap[index / 2];
                    heap[index / 2] = heap[index];
                    heap[index] = temporary;
                    index /= 2;
                }
            }
        } else if (opcode == 1) {
            if (size == 0) {
                status = 2;
            } else {
                value = @intCast(heap[1]);
                heap[1] = heap[size];
                heap[size] = 0;
                size -= 1;
                var index: usize = 1;
                while (index * 2 <= size) {
                    var child = index * 2;
                    if (child < size and heap[child + 1] > heap[child]) child += 1;
                    if (heap[index] >= heap[child]) break;
                    const temporary = heap[index];
                    heap[index] = heap[child];
                    heap[child] = temporary;
                    index = child;
                }
            }
        } else if (opcode == 2) {
            if (size > 0) value = @intCast(heap[1]);
        } else if (opcode == 3) {
            if (size == 0) value = 1;
        } else if (opcode == 4) {
            if (size == capacity) value = 1;
        } else {
            value = @intCast(size);
        }

        storeI64Le(output, operation * 16, status);
        storeI64Le(output, operation * 16 + 8, value);
    }
    return @intCast(needed);
}
