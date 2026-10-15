module climbing_stairs;

// Count ways to climb n stairs using one or two steps per move.
fn long climbing_stairs(long steps) @export("climbing_stairs") {
    if (steps < 1 || steps > 45) return -1;
    long previous = 1;
    long current = 1;
    for (long index = 2; index <= steps; index++) {
        long next = previous + current;
        previous = current;
        current = next;
    }
    return current;
}
