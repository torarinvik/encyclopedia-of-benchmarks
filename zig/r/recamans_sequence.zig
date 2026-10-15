export fn recamans_sequence(index: i64) i64 {
    if (index < 0 or index > 32) return -1;
    var seen: [529]bool = [_]bool{false} ** 529;
    seen[0] = true;
    var previous: i64 = 0;
    var step: i64 = 1;
    while (step <= index) : (step += 1) {
        var candidate = previous - step;
        const candidate_index: usize = if (candidate < 0) 0 else @intCast(candidate);
        if (candidate < 0 or seen[candidate_index]) candidate = previous + step;
        const next_index: usize = @intCast(candidate);
        seen[next_index] = true;
        previous = candidate;
    }
    return previous;
}
