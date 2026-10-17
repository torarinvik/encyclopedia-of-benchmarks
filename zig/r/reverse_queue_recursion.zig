const MAX_QUEUE_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 34;

fn reverseQueueRecursive(queue: []u8, front: *usize, size: *usize) void {
    if (size.* == 0) return;
    const capacity = queue.len;
    const value = queue[front.*];
    front.* = (front.* + 1) % capacity;
    size.* -= 1;
    reverseQueueRecursive(queue, front, size);
    const rear = (front.* + size.*) % capacity;
    queue[rear] = value;
    size.* += 1;
}

export fn reverse_queue_recursion(input: [*c]const i64, input_length: usize,
                                  output: [*c]u8, output_capacity: usize) i64 {
    if (input == null) {
        if (input_length != 1) return -1;
        return if (output == null) -2 else 0;
    }
    if (input_length < 1 or input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 or input[0] > MAX_QUEUE_LENGTH) return -1;
    const queue_length: usize = @intCast(input[0]);
    if (input_length != queue_length + 1) return -1;
    for (0..queue_length) |index| {
        if (input[index + 1] < 0 or input[index + 1] > 255) return -1;
    }
    if (output == null or output_capacity < queue_length) return -2;

    var queue: [MAX_QUEUE_LENGTH]u8 = [_]u8{0} ** MAX_QUEUE_LENGTH;
    for (0..queue_length) |index| queue[index] = @intCast(input[index + 1]);
    var front: usize = 0;
    var size = queue_length;
    reverseQueueRecursive(queue[0..queue_length], &front, &size);
    const result = output;
    for (0..queue_length) |index| result[index] = queue[(front + index) % queue_length];
    return @intCast(queue_length);
}
