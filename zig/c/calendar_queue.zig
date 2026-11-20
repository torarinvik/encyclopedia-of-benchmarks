const MAX_OPS: usize = 128;
const MAX_LIVE: usize = 64;
const MAX_BUCKETS: usize = 64;
const MAX_PRIORITY: i64 = 1_000_000;
const MAX_INPUT: usize = 1 + 2 * MAX_OPS + 1;

const Event = struct { priority: i64 = 0, id: i64 = 0, next: usize = MAX_LIVE, active: bool = false };
const Calendar = struct {
    events: [MAX_LIVE]Event = [_]Event{.{}} ** MAX_LIVE,
    heads: [MAX_BUCKETS]usize = [_]usize{MAX_LIVE} ** MAX_BUCKETS,
    bucket_count: usize = 2,
    live: usize = 0,
    next_id: i64 = 0,
    last_priority: i64 = 0,
    last_bucket: usize = 0,
    width_num: i64 = 1,
    width_den: i64 = 1,
    top_num: i64 = 3,
    top_den: i64 = 2,

    fn less(a: Event, b: Event) bool {
        return a.priority < b.priority or (a.priority == b.priority and a.id < b.id);
    }
    fn virtualBucket(self: *const Calendar, priority: i64) usize {
        return @intCast(@divTrunc(priority * self.width_den, self.width_num));
    }
    fn resetCursor(self: *Calendar, priority: i64) void {
        const virtual_index = self.virtualBucket(priority);
        self.last_bucket = virtual_index % self.bucket_count;
        self.top_num = (2 * @as(i64, @intCast(virtual_index)) + 3) * self.width_num;
        self.top_den = 2 * self.width_den;
    }
    fn insert(self: *Calendar, slot: usize) void {
        const bucket = self.virtualBucket(self.events[slot].priority) % self.bucket_count;
        var previous: usize = MAX_LIVE;
        var current = self.heads[bucket];
        while (current != MAX_LIVE and less(self.events[current], self.events[slot])) {
            previous = current;
            current = self.events[current].next;
        }
        self.events[slot].next = current;
        if (previous == MAX_LIVE) self.heads[bucket] = slot else self.events[previous].next = slot;
    }
    fn gcd(a0: i64, b0: i64) i64 {
        var a = a0; var b = b0;
        while (b != 0) { const r = @rem(a, b); a = b; b = r; }
        return a;
    }
    fn newWidth(self: *const Calendar) [2]i64 {
        var ordered: [MAX_LIVE]Event = [_]Event{.{}} ** MAX_LIVE;
        var count: usize = 0;
        for (self.events) |event| {
            if (!event.active) continue;
            var at = count;
            while (at > 0 and less(event, ordered[at - 1])) : (at -= 1) { ordered[at] = ordered[at - 1]; }
            ordered[at] = event;
            count += 1;
        }
        if (count < 2) return .{ 1, 1 };
        const samples = if (count <= 5) count else @min(25, 5 + count / 10);
        const gaps = samples - 1;
        var sum: i64 = 0;
        for (0..gaps) |i| sum += ordered[i + 1].priority - ordered[i].priority;
        if (sum == 0) return .{ 1, 1 };
        var kept_sum: i64 = 0; var kept: i64 = 0;
        for (0..gaps) |i| {
            const gap = ordered[i + 1].priority - ordered[i].priority;
            if (gap * @as(i64, @intCast(gaps)) <= 2 * sum) { kept_sum += gap; kept += 1; }
        }
        if (kept_sum == 0 or kept == 0) return .{ 1, 1 };
        const numerator = 3 * kept_sum;
        const divisor = gcd(numerator, kept);
        return .{ @divTrunc(numerator, divisor), @divTrunc(kept, divisor) };
    }
    fn resize(self: *Calendar, new_count: usize) void {
        const width = self.newWidth();
        self.bucket_count = new_count; self.width_num = width[0]; self.width_den = width[1];
        @memset(&self.heads, MAX_LIVE);
        self.resetCursor(self.last_priority);
        for (0..MAX_LIVE) |slot| if (self.events[slot].active) self.insert(slot);
    }
    fn enqueue(self: *Calendar, priority: i64) bool {
        if (priority < 0 or priority > MAX_PRIORITY or priority < self.last_priority or self.live == MAX_LIVE) return false;
        var slot: usize = MAX_LIVE;
        for (0..MAX_LIVE) |i| if (!self.events[i].active) { slot = i; break; };
        if (slot == MAX_LIVE) return false;
        self.events[slot] = .{ .priority = priority, .id = self.next_id, .active = true };
        self.next_id += 1; self.live += 1; self.insert(slot);
        if (self.live > 2 * self.bucket_count) self.resize(self.bucket_count * 2);
        return true;
    }
    fn dequeue(self: *Calendar) ?Event {
        if (self.live == 0) return null;
        var bucket = self.last_bucket;
        while (true) {
            const slot = self.heads[bucket];
            if (slot != MAX_LIVE and self.events[slot].priority * self.top_den < self.top_num) {
                const event = self.events[slot]; self.heads[bucket] = event.next;
                self.events[slot].active = false; self.live -= 1;
                self.last_bucket = bucket; self.last_priority = event.priority;
                if (self.bucket_count > 2 and @as(i64, @intCast(self.live)) < @as(i64, @intCast(self.bucket_count / 2)) - 2) self.resize(self.bucket_count / 2);
                return event;
            }
            bucket = (bucket + 1) % self.bucket_count;
            self.top_num += 2 * self.width_num;
            if (bucket == self.last_bucket) {
                var minimum: usize = MAX_LIVE;
                for (0..self.bucket_count) |i| {
                    const head = self.heads[i];
                    if (head != MAX_LIVE and (minimum == MAX_LIVE or less(self.events[head], self.events[minimum]))) minimum = head;
                }
                if (minimum == MAX_LIVE) return null;
                self.last_priority = self.events[minimum].priority;
                self.resetCursor(self.last_priority);
                bucket = self.last_bucket;
            }
        }
    }
};

fn putI64(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn calendar_queue(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT) return -1;
    const count = input[0];
    if (count < 0 or count > @as(i64, @intCast(MAX_OPS)) or
        length != 1 + 2 * @as(usize, @intCast(count))) return -1;
    var queue = Calendar{};
    var trace: [2 * MAX_OPS]i64 = [_]i64{0} ** (2 * MAX_OPS);
    var dequeued: usize = 0;
    for (0..@intCast(count)) |step| {
        const opcode = input[1 + 2 * step]; const argument = input[2 + 2 * step];
        if (opcode == 1) {
            if (!queue.enqueue(argument)) return -1;
        } else if (opcode == 2) {
            if (argument != 0) return -1;
            const event = queue.dequeue() orelse return -1;
            trace[2 * dequeued] = event.id; trace[2 * dequeued + 1] = event.priority; dequeued += 1;
        } else return -1;
    }
    const bytes = (1 + 2 * dequeued) * 8;
    if (output == null or capacity < bytes) return -2;
    putI64(output, 0, @intCast(dequeued));
    for (0..2 * dequeued) |word| putI64(output, word + 1, trace[word]);
    return @intCast(bytes);
}
