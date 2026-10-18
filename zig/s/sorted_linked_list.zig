const MAX_INITIAL_COUNT: usize = 16;
const MAX_INPUT_LENGTH: usize = 20;
const MAX_OUTPUT_WORDS: usize = 18;

const ListNode = struct { value: i32 = 0, next: i32 = -1 };

fn putI64Le(output: *[MAX_OUTPUT_WORDS * 8]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn sorted_linked_list(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 3 or input_length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 0 or values[0] > MAX_INITIAL_COUNT) return -1;
    const count: usize = @intCast(values[0]);
    if (input_length != count + 3) return -1;

    var nodes = [_]ListNode{.{}} ** (MAX_INITIAL_COUNT + 1);
    for (0..count) |index| {
        const value = values[index + 1];
        if (value < std.math.minInt(i32) or value > std.math.maxInt(i32) or
            (index > 0 and values[index] >= value)) return -1;
        nodes[index] = .{ .value = @intCast(value), .next = if (index + 1 < count) @intCast(index + 1) else -1 };
    }
    const operation_value = values[count + 1];
    const key_value = values[count + 2];
    if (operation_value < 0 or operation_value > 2 or
        key_value < std.math.minInt(i32) or key_value > std.math.maxInt(i32)) return -1;
    const operation: usize = @intCast(operation_value);
    const key: i32 = @intCast(key_value);
    var head: i32 = if (count == 0) -1 else 0;
    var tail: i32 = if (count == 0) -1 else @intCast(count - 1);

    if (operation == 0) {
        var node = head;
        while (node >= 0) : (node = nodes[@intCast(node)].next) {
            if (nodes[@intCast(node)].value == key) return -1;
        }
    }

    var staged = [_]i64{0} ** MAX_OUTPUT_WORDS;
    var word_count: usize = 0;
    if (operation == 0) {
        const new_node: i32 = @intCast(count);
        nodes[@intCast(new_node)] = .{ .value = key, .next = -1 };
        if (head < 0) {
            head = new_node;
            tail = new_node;
        } else if (key < nodes[@intCast(head)].value) {
            nodes[@intCast(new_node)].next = head;
            head = new_node;
        } else if (key > nodes[@intCast(tail)].value) {
            nodes[@intCast(tail)].next = new_node;
            tail = new_node;
        } else {
            var previous = head;
            while (nodes[@intCast(previous)].next >= 0 and
                nodes[@intCast(nodes[@intCast(previous)].next)].value < key) {
                previous = nodes[@intCast(previous)].next;
            }
            nodes[@intCast(new_node)].next = nodes[@intCast(previous)].next;
            nodes[@intCast(previous)].next = new_node;
            if (nodes[@intCast(new_node)].next < 0) tail = new_node;
        }
        staged[word_count] = @intCast(count + 1);
        word_count += 1;
        var node = head;
        while (node >= 0) : (node = nodes[@intCast(node)].next) {
            staged[word_count] = nodes[@intCast(node)].value;
            word_count += 1;
        }
    } else if (operation == 1) {
        var found: i64 = 0;
        var node = head;
        while (node >= 0) : (node = nodes[@intCast(node)].next) {
            if (nodes[@intCast(node)].value == key) { found = 1; break; }
        }
        staged[word_count] = found;
        word_count += 1;
    } else {
        var deleted: i64 = 0;
        if (head >= 0 and nodes[@intCast(head)].value == key) {
            head = nodes[@intCast(head)].next;
            if (head < 0) tail = -1;
            deleted = 1;
        } else {
            var previous = head;
            while (previous >= 0 and nodes[@intCast(previous)].next >= 0) {
                const candidate = nodes[@intCast(previous)].next;
                if (nodes[@intCast(candidate)].value == key) {
                    nodes[@intCast(previous)].next = nodes[@intCast(candidate)].next;
                    if (tail == candidate) tail = previous;
                    deleted = 1;
                    break;
                }
                previous = candidate;
            }
        }
        staged[word_count] = deleted;
        word_count += 1;
        var remaining: usize = 0;
        var node = head;
        while (node >= 0) : (node = nodes[@intCast(node)].next) remaining += 1;
        staged[word_count] = @intCast(remaining);
        word_count += 1;
        node = head;
        while (node >= 0) : (node = nodes[@intCast(node)].next) {
            staged[word_count] = nodes[@intCast(node)].value;
            word_count += 1;
        }
    }

    const output_bytes = word_count * 8;
    const out = output orelse return -2;
    if (capacity < output_bytes) return -2;
    var packed: [MAX_OUTPUT_WORDS * 8]u8 = undefined;
    for (0..word_count) |index| putI64Le(&packed, index * 8, staged[index]);
    @memcpy(out[0..output_bytes], packed[0..output_bytes]);
    return @intCast(output_bytes);
}
