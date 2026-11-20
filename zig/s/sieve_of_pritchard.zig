/// Count primes through limit with Pritchard's dynamic wheel sieve.
const MAX_LIMIT: i64 = 1024;
const LINK_COUNT: usize = 1026;

export fn sieve_of_pritchard(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 1 or length > 2) return -1;
    if (length != 1 or input[0] < 2 or input[0] > MAX_LIMIT) return -1;

    const limit: i32 = @intCast(input[0]);
    const sentinel = limit + 1;
    var next_node: [LINK_COUNT]i32 = @splat(0);
    var previous: [LINK_COUNT]i32 = @splat(0);
    next_node[1] = sentinel;
    next_node[@intCast(sentinel)] = sentinel;
    previous[@intCast(sentinel)] = 1;
    var wheel_length: i32 = 2;
    var prime: i32 = 3;
    var prime_count: i64 = 1;

    while (prime * prime <= limit) {
        if (wheel_length < limit) {
            const product = prime * wheel_length;
            const target = if (product < limit) product else limit;
            var wheel_value: i32 = 1;
            var candidate = wheel_length + 1;
            while (candidate <= target) {
                const tail = previous[@intCast(sentinel)];
                next_node[@intCast(tail)] = candidate;
                previous[@intCast(candidate)] = tail;
                next_node[@intCast(candidate)] = sentinel;
                previous[@intCast(sentinel)] = candidate;
                wheel_value = next_node[@intCast(wheel_value)];
                candidate = wheel_length + wheel_value;
            }
            wheel_length = target;
        }

        var wheel_value = prime;
        while (prime * wheel_value <= wheel_length)
            wheel_value = next_node[@intCast(wheel_value)];
        while (wheel_value > 1) {
            wheel_value = previous[@intCast(wheel_value)];
            const removed = prime * wheel_value;
            const left = previous[@intCast(removed)];
            const right = next_node[@intCast(removed)];
            next_node[@intCast(left)] = right;
            previous[@intCast(right)] = left;
        }
        prime_count += 1;
        prime = next_node[1];
    }

    if (wheel_length < limit) {
        var wheel_value: i32 = 1;
        var candidate = wheel_length + 1;
        while (candidate <= limit) {
            const tail = previous[@intCast(sentinel)];
            next_node[@intCast(tail)] = candidate;
            previous[@intCast(candidate)] = tail;
            next_node[@intCast(candidate)] = sentinel;
            previous[@intCast(sentinel)] = candidate;
            wheel_value = next_node[@intCast(wheel_value)];
            candidate = wheel_length + wheel_value;
        }
        wheel_length = limit;
    }

    var remaining: i64 = 0;
    var value = next_node[1];
    while (value != sentinel) {
        remaining += 1;
        value = next_node[@intCast(value)];
    }
    return prime_count + remaining;
}
