const MAX_INITIAL: usize = 64;
const MAX_OPERATIONS: usize = 128;
const MAX_KEYS: usize = MAX_INITIAL + MAX_OPERATIONS;
const MAX_INPUT: usize = MAX_INITIAL + 2 + 2 * MAX_OPERATIONS;

const IntervalHeap = struct {
    keys: [MAX_KEYS]i32 = [_]i32{0} ** MAX_KEYS,
    count: usize = 0,

    fn highIndex(self: *const IntervalHeap, node: usize) usize {
        const high = 2 * node + 1;
        return if (high < self.count) high else 2 * node;
    }

    fn siftUpLow(self: *IntervalHeap, start: usize) void {
        var node = start;
        while (node > 0) {
            const parent = (node - 1) / 2;
            const low = 2 * node;
            const parent_low = 2 * parent;
            if (self.keys[low] >= self.keys[parent_low]) return;
            const temp = self.keys[low];
            self.keys[low] = self.keys[parent_low];
            self.keys[parent_low] = temp;
            node = parent;
        }
    }

    fn siftUpHigh(self: *IntervalHeap, start: usize) void {
        var node = start;
        while (node > 0) {
            const parent = (node - 1) / 2;
            const high = self.highIndex(node);
            const parent_high = self.highIndex(parent);
            if (self.keys[high] <= self.keys[parent_high]) return;
            const temp = self.keys[high];
            self.keys[high] = self.keys[parent_high];
            self.keys[parent_high] = temp;
            node = parent;
        }
    }

    fn insert(self: *IntervalHeap, value: i32) void {
        const key_index = self.count;
        self.keys[key_index] = value;
        self.count += 1;
        const node = key_index / 2;
        if (key_index % 2 == 1 and self.keys[key_index] < self.keys[key_index - 1]) {
            const temp = self.keys[key_index];
            self.keys[key_index] = self.keys[key_index - 1];
            self.keys[key_index - 1] = temp;
        }
        self.siftUpLow(node);
        self.siftUpHigh(node);
    }

    fn extractMin(self: *IntervalHeap) i32 {
        const result = self.keys[0];
        self.count -= 1;
        const last = self.keys[self.count];
        if (self.count == 0) return result;
        self.keys[0] = last;
        var node: usize = 0;
        while (true) {
            const left = 2 * node + 1;
            if (2 * left >= self.count) return result;
            const right = left + 1;
            var child = left;
            if (2 * right < self.count and self.keys[2 * right] < self.keys[2 * left]) child = right;
            const node_low = 2 * node;
            const child_low = 2 * child;
            if (self.keys[child_low] >= self.keys[node_low]) return result;
            const temp = self.keys[node_low];
            self.keys[node_low] = self.keys[child_low];
            self.keys[child_low] = temp;
            const child_high = self.highIndex(child);
            if (self.keys[child_high] < self.keys[child_low]) {
                const pair_temp = self.keys[child_high];
                self.keys[child_high] = self.keys[child_low];
                self.keys[child_low] = pair_temp;
            }
            node = child;
        }
    }

    fn extractMax(self: *IntervalHeap) i32 {
        if (self.count <= 2) {
            self.count -= 1;
            return self.keys[self.count];
        }
        const result = self.keys[1];
        self.count -= 1;
        self.keys[1] = self.keys[self.count];
        var node: usize = 0;
        while (true) {
            const left = 2 * node + 1;
            if (2 * left >= self.count) return result;
            const right = left + 1;
            var child = left;
            if (2 * right < self.count and self.keys[self.highIndex(left)] < self.keys[self.highIndex(right)]) child = right;
            const node_high = self.highIndex(node);
            const child_high = self.highIndex(child);
            if (self.keys[node_high] >= self.keys[child_high]) return result;
            const temp = self.keys[node_high];
            self.keys[node_high] = self.keys[child_high];
            self.keys[child_high] = temp;
            const child_low = 2 * child;
            if (self.keys[child_high] < self.keys[child_low]) {
                const pair_temp = self.keys[child_high];
                self.keys[child_high] = self.keys[child_low];
                self.keys[child_low] = pair_temp;
            }
            node = child;
        }
    }
};

fn writeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

fn sortI32(values: *[MAX_KEYS]i32, count: usize) void {
    for (1..count) |index| {
        const value = values[index];
        var position = index;
        while (position > 0 and values[position - 1] > value) : (position -= 1) values[position] = values[position - 1];
        values[position] = value;
    }
}

export fn interval_heap_double_ended(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 64) return -1;
    const initial_count: usize = @intCast(values[0]);
    if (length < initial_count + 2 or values[initial_count + 1] < 0 or values[initial_count + 1] > 128) return -1;
    const operation_count: usize = @intCast(values[initial_count + 1]);
    if (length != initial_count + 2 + 2 * operation_count) return -1;
    for (values[1..initial_count + 1]) |value| if (value < -2147483648 or value > 2147483647) return -1;
    for (0..operation_count) |op| {
        const opcode = values[initial_count + 2 + 2 * op];
        const argument = values[initial_count + 3 + 2 * op];
        if (opcode < 0 or opcode > 5) return -1;
        if (opcode == 0) {
            if (argument < -2147483648 or argument > 2147483647) return -1;
        } else if (argument != 0) return -1;
    }

    var heap = IntervalHeap{};
    for (values[1..initial_count + 1]) |value| heap.insert(@intCast(value));
    var events = [_]i64{0} ** MAX_OPERATIONS;
    var event_count: usize = 0;
    for (0..operation_count) |op| {
        const opcode = values[initial_count + 2 + 2 * op];
        const argument: i32 = @intCast(values[initial_count + 3 + 2 * op]);
        if (opcode == 0) heap.insert(argument) else if (opcode == 1) {
            if (heap.count == 0) return -1;
            events[event_count] = heap.keys[0]; event_count += 1;
        } else if (opcode == 2) {
            if (heap.count == 0) return -1;
            events[event_count] = heap.keys[heap.highIndex(0)]; event_count += 1;
        } else if (opcode == 3) {
            if (heap.count == 0) return -1;
            events[event_count] = heap.extractMin(); event_count += 1;
        } else if (opcode == 4) {
            if (heap.count == 0) return -1;
            events[event_count] = heap.extractMax(); event_count += 1;
        } else { events[event_count] = @intCast(heap.count); event_count += 1; }
    }
    var sorted = heap.keys;
    sortI32(&sorted, heap.count);
    const required = (2 + event_count + heap.count) * 8;
    if (output == null or capacity < required) return -2;
    const out = output.?;
    var offset: usize = 0;
    writeI64Le(out, offset, @intCast(event_count)); offset += 8;
    for (events[0..event_count]) |value| { writeI64Le(out, offset, value); offset += 8; }
    writeI64Le(out, offset, @intCast(heap.count)); offset += 8;
    for (sorted[0..heap.count]) |value| { writeI64Le(out, offset, value); offset += 8; }
    return @intCast(required);
}
