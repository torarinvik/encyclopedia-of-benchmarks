// Uncompiled and unexecuted weighted-binary-search draft.
const State = struct { score: i64, count: i64 };
fn evaluate(weights: []const i64, penalty: i64) State {
    var two = State{ .score = 0, .count = 0 };
    var one = two;
    for (weights) |weight| {
        const take = State{ .score = two.score+weight-penalty, .count = two.count+1 };
        var current = one;
        if (take.score > one.score or (take.score == one.score and take.count > one.count)) current = take;
        two = one; one = current;
    }
    return one;
}
export fn wqs_path_independent_set(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 130) return -1000000000;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > 128 or input[1] < 0 or input[1] > @divTrunc(input[0]+1, 2)) return -1000000000;
    const n: usize = @intCast(input[0]);
    if (length != n+2) return -1000000000;
    const weights = input[2..length];
    for (weights) |x| if (x < -1000 or x > 1000) { return -1000000000; };
    var low: i64 = -256001; var high: i64 = 256001;
    while (low < high) {
        const middle = low+@divTrunc(high-low+1, 2);
        if (evaluate(weights, middle).count >= input[1]) { low = middle; } else { high = middle-1; }
    }
    return evaluate(weights, low).score+low*input[1];
}
