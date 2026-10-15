/// Count task assignments with one distinct eligible task per person.
const MAX_STATES: usize = 4096;

export fn assignment_using_bitmask(input: [*]const i64, length: usize) i64 {
    if (length < 2) return -1;
    const people = input[0];
    const tasks = input[1];
    if (people < 0 or people > 10 or tasks < 0 or tasks > 10 or length != 2 + @as(usize, @intCast(people))) return -1;
    const valid_tasks = (@as(i64, 1) << @intCast(tasks)) - 1;
    for (0..@intCast(people)) |person| {
        const mask = input[2 + person];
        if (mask < 0 or mask > valid_tasks) return -1;
    }

    const states: usize = @as(usize, 1) << @intCast(people);
    var ways: [MAX_STATES]i64 = @splat(0);
    var next: [MAX_STATES]i64 = @splat(0);
    ways[0] = 1;
    for (0..@intCast(tasks)) |task| {
        @memset(next[0..states], 0);
        for (0..states) |mask| {
            const count = ways[mask];
            if (count == 0) continue;
            next[mask] += count;
            for (0..@intCast(people)) |person| {
                const bit = @as(usize, 1) << @intCast(person);
                if ((mask & bit) == 0 and (input[2 + person] & (@as(i64, 1) << @intCast(task))) != 0) {
                    next[mask | bit] += count;
                }
            }
        }
        ways = next;
    }
    return ways[states - 1];
}
