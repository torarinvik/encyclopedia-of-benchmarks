fn betterChoice(mode: i64, candidate: usize, best: usize,
                arrival: *const [32]i64, burst: *const [32]i64,
                remaining: *const [32]i64, priority: *const [32]i64) bool {
    if (mode == 1) return burst[candidate] < burst[best]
        or (burst[candidate] == burst[best] and (arrival[candidate] < arrival[best]
        or (arrival[candidate] == arrival[best] and candidate < best)));
    if (mode == 2) return remaining[candidate] < remaining[best]
        or (remaining[candidate] == remaining[best] and (arrival[candidate] < arrival[best]
        or (arrival[candidate] == arrival[best] and candidate < best)));
    return priority[candidate] < priority[best]
        or (priority[candidate] == priority[best] and candidate < best);
}

fn putI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn cpu_scheduling_algorithms(input: ?[*]const i64, length: usize,
                                    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 3 + 4 * 32) return -1;
    const values = input.?[0..length];
    const mode = values[0];
    const rawCount = values[1];
    const quantum = values[2];
    if (mode < 0 or mode > 5 or rawCount < 0 or rawCount > 32 or quantum < 1 or quantum > 32) return -1;
    const count: usize = @intCast(rawCount);
    if (length != 3 + 4 * count) return -1;

    var ids: [32]i64 = @splat(0);
    var arrival: [32]i64 = @splat(0);
    var burst: [32]i64 = @splat(0);
    var priority: [32]i64 = @splat(0);
    var remaining: [32]i64 = @splat(0);
    var completion: [32]i64 = @splat(-1);
    var firstRun: [32]i64 = @splat(-1);
    var order: [32]usize = @splat(0);
    for (0..count) |i| {
        const base = 3 + 4 * i;
        ids[i] = values[base]; arrival[i] = values[base + 1];
        burst[i] = values[base + 2]; priority[i] = values[base + 3];
        if (ids[i] < 0 or ids[i] >= 32 or arrival[i] < 0 or arrival[i] > 256
            or burst[i] < 1 or burst[i] > 32 or priority[i] < -32 or priority[i] > 32) return -1;
        for (0..i) |j| if (ids[j] == ids[i]) return -1;
        remaining[i] = burst[i]; order[i] = i;
    }
    const bytes = count * 56;
    if (bytes > 0 and (output == null or capacity < bytes)) return -2;

    if (mode == 0 or mode == 5) {
        var i: usize = 1;
        while (i < count) : (i += 1) {
            const key = order[i];
            var j = i;
            while (j > 0 and arrival[order[j - 1]] > arrival[key]) {
                order[j] = order[j - 1];
                j -= 1;
            }
            order[j] = key;
        }
    }

    var time: i64 = 0;
    if (mode == 0) {
        for (0..count) |position| {
            const i = order[position];
            if (time < arrival[i]) time = arrival[i];
            firstRun[i] = time; time += burst[i]; completion[i] = time;
        }
    } else if (mode == 1 or mode == 3) {
        var done: usize = 0;
        while (done < count) {
            var best = count;
            for (0..count) |i| {
                if (completion[i] >= 0 or arrival[i] > time) continue;
                if (best == count or betterChoice(mode, i, best, &arrival, &burst, &remaining, &priority)) best = i;
            }
            if (best == count) { time += 1; continue; }
            firstRun[best] = time; time += burst[best]; completion[best] = time; done += 1;
        }
    } else if (mode == 2 or mode == 4) {
        var done: usize = 0;
        while (done < count) {
            var best = count;
            for (0..count) |i| {
                if (remaining[i] <= 0 or arrival[i] > time) continue;
                if (best == count or betterChoice(mode, i, best, &arrival, &burst, &remaining, &priority)) best = i;
            }
            if (best == count) { time += 1; continue; }
            if (firstRun[best] < 0) firstRun[best] = time;
            remaining[best] -= 1; time += 1;
            if (remaining[best] == 0) { completion[best] = time; done += 1; }
        }
    } else {
        var queue: [64]usize = @splat(0);
        var head: usize = 0; var tail: usize = 0; var queueSize: usize = 0;
        var nextArrival: usize = 0; var done: usize = 0;
        while (done < count) {
            while (nextArrival < count and arrival[order[nextArrival]] <= time) {
                queue[tail] = order[nextArrival]; nextArrival += 1; tail = (tail + 1) % 64; queueSize += 1;
            }
            if (queueSize == 0) { time += 1; continue; }
            const current = queue[head]; head = (head + 1) % 64; queueSize -= 1;
            const runFor = @min(quantum, remaining[current]);
            var slot: i64 = 0;
            while (slot < runFor) : (slot += 1) {
                if (firstRun[current] < 0) firstRun[current] = time;
                remaining[current] -= 1; time += 1;
                while (nextArrival < count and arrival[order[nextArrival]] <= time) {
                    queue[tail] = order[nextArrival]; nextArrival += 1; tail = (tail + 1) % 64; queueSize += 1;
                }
            }
            if (remaining[current] > 0) { queue[tail] = current; tail = (tail + 1) % 64; queueSize += 1; }
            else { completion[current] = time; done += 1; }
        }
    }

    if (bytes > 0) {
        const result = output.?[0..bytes];
        for (0..count) |i| {
            const turnaround = completion[i] - arrival[i];
            const fields = [7]i64{ ids[i], arrival[i], burst[i], completion[i], turnaround,
                                   turnaround - burst[i], firstRun[i] - arrival[i] };
            for (0..7) |field| putI64Le(result, i * 56 + field * 8, fields[field]);
        }
    }
    return @intCast(bytes);
}
