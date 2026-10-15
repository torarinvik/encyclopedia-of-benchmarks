/// Count ways to climb n stairs using one or two steps per move.
export fn climbing_stairs(steps: i64) i64 {
    if (steps < 1 or steps > 45) return -1;
    var previous: i64 = 1;
    var current: i64 = 1;
    var index: i64 = 2;
    while (index <= steps) : (index += 1) {
        const next = previous + current;
        previous = current;
        current = next;
    }
    return current;
}
