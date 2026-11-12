const MAX_JOBS: usize = 12;

const Job = struct {
    deadline: i64,
    duration: i64,
    id: usize,
};

const Heap = struct {
    durations: [MAX_JOBS]i64 = @splat(0),
    ids: [MAX_JOBS]usize = @splat(0),
    size: usize = 0,

    fn before(left_duration: i64, left_id: usize, right_duration: i64, right_id: usize) bool {
        return left_duration < right_duration or
            (left_duration == right_duration and left_id < right_id);
    }

    fn push(self: *Heap, duration: i64, id: usize) void {
        var index = self.size;
        self.size += 1;
        while (index > 0) {
            const parent = (index - 1) / 2;
            if (!before(duration, id, self.durations[parent], self.ids[parent])) break;
            self.durations[index] = self.durations[parent];
            self.ids[index] = self.ids[parent];
            index = parent;
        }
        self.durations[index] = duration;
        self.ids[index] = id;
    }

    fn pop(self: *Heap) struct { duration: i64, id: usize } {
        const result = .{ .duration = self.durations[0], .id = self.ids[0] };
        self.size -= 1;
        if (self.size == 0) return result;
        const last_duration = self.durations[self.size];
        const last_id = self.ids[self.size];
        var index: usize = 0;
        while (2 * index + 1 < self.size) {
            var child = 2 * index + 1;
            if (child + 1 < self.size and before(self.durations[child + 1], self.ids[child + 1],
                                                 self.durations[child], self.ids[child])) child += 1;
            if (!before(self.durations[child], self.ids[child], last_duration, last_id)) break;
            self.durations[index] = self.durations[child];
            self.ids[index] = self.ids[child];
            index = child;
        }
        self.durations[index] = last_duration;
        self.ids[index] = last_id;
        return result;
    }
};

export fn max_jobs_before_deadlines(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 1 + 2 * MAX_JOBS) return -1;
    const count_value = input[0];
    if (count_value < 0 or count_value > @as(i64, @intCast(MAX_JOBS)) or
        length != 1 + 2 * @as(usize, @intCast(count_value))) return -1;
    const count: usize = @intCast(count_value);
    var jobs: [MAX_JOBS]Job = undefined;
    for (0..count) |i| {
        const deadline = input[1 + 2 * i];
        const duration = input[2 + 2 * i];
        if (deadline < 0 or deadline > 1000 or duration < 1 or duration > 1000) return -1;
        jobs[i] = .{ .deadline = deadline, .duration = duration, .id = i };
    }
    var i: usize = 1;
    while (i < count) : (i += 1) {
        const item = jobs[i];
        var position = i;
        while (position > 0 and jobs[position - 1].deadline > item.deadline) : (position -= 1) {
            jobs[position] = jobs[position - 1];
        }
        jobs[position] = item;
    }
    var heap = Heap{};
    var completed: i64 = 0;
    var end = count;
    while (end > 0) {
        end -= 1;
        heap.push(jobs[end].duration, jobs[end].id);
        const lower: i64 = if (end == 0) 0 else jobs[end - 1].deadline;
        var interval = jobs[end].deadline - lower;
        while (interval > 0 and heap.size > 0) {
            const job = heap.pop();
            if (job.duration <= interval) {
                interval -= job.duration;
                completed += 1;
            } else {
                heap.push(job.duration - interval, job.id);
                interval = 0;
            }
        }
    }
    return completed;
}
