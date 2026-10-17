const MAX_OPERATIONS: usize = 64;
const MAX_LIVE_VALUES: usize = 32;
const MAX_INPUT_LENGTH: usize = 130;
const MAX_OUTPUT_VALUES: usize = 1024;

const Node = struct { value: i32 = 0, left: i32 = -1, right: i32 = -1, next_free: i32 = -1 };
const SkewHeap = struct {
    nodes: [MAX_LIVE_VALUES]Node = undefined,
    root: i32 = -1,
    free_head: i32 = 0,
    count: usize = 0,
    fn initialize(self: *SkewHeap) void {
        self.root = -1; self.free_head = 0; self.count = 0;
        for (0..MAX_LIVE_VALUES) |i| {
            self.nodes[i].left = -1; self.nodes[i].right = -1;
            self.nodes[i].next_free = if (i + 1 < MAX_LIVE_VALUES) @intCast(i + 1) else -1;
        }
    }
    fn merge(self: *SkewHeap, first_arg: i32, second_arg: i32) i32 {
        if (first_arg < 0) return second_arg;
        if (second_arg < 0) return first_arg;
        var first = first_arg; var second = second_arg;
        if (self.nodes[@intCast(first)].value > self.nodes[@intCast(second)].value) { const temp = first; first = second; second = temp; }
        const node: usize = @intCast(first); const old_right = self.nodes[node].right;
        self.nodes[node].right = self.nodes[node].left;
        self.nodes[node].left = self.merge(old_right, second);
        return first;
    }
    fn insert(self: *SkewHeap, value: i32) bool {
        if (self.free_head < 0) return false;
        const node: usize = @intCast(self.free_head); self.free_head = self.nodes[node].next_free;
        self.nodes[node] = .{ .value = value, .left = -1, .right = -1, .next_free = -1 };
        self.root = self.merge(self.root, @intCast(node)); self.count += 1; return true;
    }
    fn pop(self: *SkewHeap) i32 {
        const node: usize = @intCast(self.root); const value = self.nodes[node].value;
        self.root = self.merge(self.nodes[node].left, self.nodes[node].right);
        self.nodes[node].next_free = self.free_head; self.free_head = @intCast(node); self.count -= 1; return value;
    }
};

fn storeI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn skew_heap(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64, MAX_OPERATIONS)) return -1;
    const operation_count: usize = @intCast(input[0]);
    if (length != 1 + 2 * operation_count or length > MAX_INPUT_LENGTH - 1) return -1;
    var heap = SkewHeap{}; heap.initialize();
    var answers: [MAX_OUTPUT_VALUES]i64 = @splat(0); var answer_count: usize = 0;
    for (0..operation_count) |operation| {
        const opcode = input[1 + 2 * operation]; const argument = input[2 + 2 * operation];
        if (opcode < 0 or opcode > 5) return -1;
        if (opcode == 0) {
            if (argument < -2147483648 or argument > 2147483647 or heap.count == MAX_LIVE_VALUES) return -1;
            if (!heap.insert(@intCast(argument))) return -1;
        } else {
            if (argument != 0) return -1;
            if (opcode == 1) { if (heap.root < 0) return -1; answers[answer_count] = heap.nodes[@intCast(heap.root)].value; answer_count += 1; }
            else if (opcode == 2) { if (heap.root < 0) return -1; answers[answer_count] = heap.pop(); answer_count += 1; }
            else if (opcode == 3) {
                var snapshot: [MAX_LIVE_VALUES]i32 = @splat(0); var snapshot_count: usize = 0;
                while (heap.root >= 0) { snapshot[snapshot_count] = heap.pop(); snapshot_count += 1; }
                for (0..snapshot_count) |i| { if (!heap.insert(snapshot[i])) return -1; answers[answer_count] = snapshot[i]; answer_count += 1; }
            } else if (opcode == 4) { heap.initialize(); }
            else { answers[answer_count] = if (heap.count == 0) 1 else 0; answer_count += 1; }
        }
    }
    const output_bytes = answer_count * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    for (0..answer_count) |i| storeI64(output, i * 8, answers[i]);
    return @intCast(output_bytes);
}
