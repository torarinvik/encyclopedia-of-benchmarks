const MAX_INPUT_VALUES: usize = 227;
const MAX_NODES: usize = 96;
const MAX_OUTPUT_BYTES: usize = 1808;

const List = struct {
    values: [MAX_NODES]i64 = [_]i64{0} ** MAX_NODES,
    next: [MAX_NODES]i32 = [_]i32{-1} ** MAX_NODES,
    used: usize = 0,
    head: i32 = -1,
    tail: i32 = -1,
    length: usize = 0,

    fn allocate(self: *List, value: i64) i32 {
        const node: usize = self.used;
        self.used += 1;
        self.values[node] = value;
        self.next[node] = -1;
        return @intCast(node);
    }
    fn addHead(self: *List, value: i64) void {
        const node = self.allocate(value);
        self.next[@intCast(node)] = self.head;
        if (self.head < 0) self.tail = node;
        self.head = node;
        self.length += 1;
    }
    fn addTail(self: *List, value: i64) void {
        const node = self.allocate(value);
        if (self.tail < 0) self.head = node else self.next[@intCast(self.tail)] = node;
        self.tail = node;
        self.length += 1;
    }
    fn deleteHead(self: *List) DeleteResult {
        if (self.head < 0) return .{ .found = false, .value = 0 };
        const node: usize = @intCast(self.head);
        const value = self.values[node];
        self.head = self.next[node];
        self.length -= 1;
        if (self.length == 0) self.tail = -1;
        return .{ .found = true, .value = value };
    }
    fn deleteTail(self: *List) DeleteResult {
        if (self.tail < 0) return .{ .found = false, .value = 0 };
        const tail_index: usize = @intCast(self.tail);
        const value = self.values[tail_index];
        if (self.length == 1) {
            self.head = -1;
            self.tail = -1;
        } else {
            var previous: i32 = self.head;
            while (self.next[@intCast(previous)] != self.tail) previous = self.next[@intCast(previous)];
            self.next[@intCast(previous)] = -1;
            self.tail = previous;
        }
        self.length -= 1;
        return .{ .found = true, .value = value };
    }
    fn deletePosition(self: *List, position: usize) DeleteResult {
        if (self.length == 0) return .{ .found = false, .value = 0 };
        if (position == 1) return self.deleteHead();
        if (position >= self.length) return self.deleteTail();
        var previous: i32 = self.head;
        for (1..position - 1) |_| previous = self.next[@intCast(previous)];
        const previous_index: usize = @intCast(previous);
        const node: usize = @intCast(self.next[previous_index]);
        const value = self.values[node];
        self.next[previous_index] = self.next[node];
        self.length -= 1;
        return .{ .found = true, .value = value };
    }
    fn reverse(self: *List) void {
        var previous: i32 = -1;
        var current = self.head;
        self.tail = self.head;
        while (current >= 0) {
            const node: usize = @intCast(current);
            const following = self.next[node];
            self.next[node] = previous;
            previous = current;
            current = following;
        }
        self.head = previous;
    }
    fn reverseRange(self: *List, left: usize, right: usize) void {
        var before: i32 = -1;
        var start = self.head;
        for (1..left) |_| {
            before = start;
            start = self.next[@intCast(start)];
        }
        var previous: i32 = -1;
        var current = start;
        for (left..right + 1) |_| {
            const node: usize = @intCast(current);
            const following = self.next[node];
            self.next[node] = previous;
            previous = current;
            current = following;
        }
        self.next[@intCast(start)] = current;
        if (before < 0) self.head = previous else self.next[@intCast(before)] = previous;
        if (right == self.length) self.tail = start;
    }
};

const DeleteResult = struct { found: bool, value: i64 };

fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn singlylinkedlist(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (length < 2 or length > MAX_INPUT_VALUES) return -1;
    const initial_count_value = values[0];
    const operation_count_value = values[1];
    if (initial_count_value < 0 or initial_count_value > 32 or operation_count_value < 0 or operation_count_value > 64) return -1;
    const initial_count: usize = @intCast(initial_count_value);
    const operation_count: usize = @intCast(operation_count_value);
    if (length < 2 + initial_count) return -1;
    var list = List{};
    for (0..initial_count) |i| {
        const value = values[2 + i];
        if (value < -1_000_000 or value > 1_000_000) return -1;
        list.addTail(value);
    }
    var results = [_]i64{0} ** 128;
    var cursor: usize = 2 + initial_count;
    for (0..operation_count) |operation| {
        if (cursor >= length) return -1;
        const opcode = values[cursor];
        cursor += 1;
        var arg1: i64 = 0;
        var arg2: i64 = 0;
        if (opcode == 0 or opcode == 1 or opcode == 4) {
            if (cursor >= length) return -1;
            arg1 = values[cursor];
            cursor += 1;
        } else if (opcode == 6) {
            if (length - cursor < 2) return -1;
            arg1 = values[cursor];
            arg2 = values[cursor + 1];
            cursor += 2;
        } else if (opcode != 2 and opcode != 3 and opcode != 5) return -1;

        var success: i64 = 1;
        var result_value: i64 = 0;
        if (opcode == 0 or opcode == 1) {
            if (arg1 < -1_000_000 or arg1 > 1_000_000) return -1;
            if (opcode == 0) list.addHead(arg1) else list.addTail(arg1);
        } else if (opcode == 2) {
            const deleted = list.deleteHead();
            if (!deleted.found) success = 0;
            result_value = deleted.value;
        } else if (opcode == 3) {
            const deleted = list.deleteTail();
            if (!deleted.found) success = 0;
            result_value = deleted.value;
        } else if (opcode == 4) {
            if (list.length == 0) {
                if (arg1 != 1) return -1;
                success = 0;
            } else {
                if (arg1 < 1 or arg1 > @as(i64, @intCast(list.length + 1))) return -1;
                const deleted = list.deletePosition(@intCast(arg1));
                result_value = deleted.value;
            }
        } else if (opcode == 5) {
            list.reverse();
        } else {
            if (arg1 < 1 or arg2 < arg1 or arg2 > @as(i64, @intCast(list.length))) return -1;
            list.reverseRange(@intCast(arg1), @intCast(arg2));
        }
        results[operation * 2] = success;
        results[operation * 2 + 1] = result_value;
    }
    if (cursor != length) return -1;
    const output_values = 1 + list.length + 1 + operation_count * 2;
    const output_bytes = output_values * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    const out = output orelse return -2;
    if (capacity < output_bytes) return -2;
    putI64Le(out, 0, @intCast(list.length));
    var offset: usize = 8;
    var node = list.head;
    while (node >= 0) {
        const node_index: usize = @intCast(node);
        putI64Le(out, offset, list.values[node_index]);
        offset += 8;
        node = list.next[node_index];
    }
    putI64Le(out, offset, @intCast(operation_count));
    offset += 8;
    for (0..operation_count * 2) |i| {
        putI64Le(out, offset, results[i]);
        offset += 8;
    }
    return @intCast(output_bytes);
}
