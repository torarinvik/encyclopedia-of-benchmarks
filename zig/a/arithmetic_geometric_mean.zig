const MAX_VALUE: f64 = 1_000_000.0;
const INVALID_RESULT: f64 = -1.0;

export fn arithmetic_geometric_mean(first: f64, second: f64) f64 {
    if (first != first or second != second or first < 0.0 or second < 0.0
        or first > MAX_VALUE or second > MAX_VALUE) return INVALID_RESULT;
    if (first == second) return first;

    var arithmetic = first;
    var geometric = second;
    while (true) {
        const previous = arithmetic;
        const next_arithmetic = (arithmetic + geometric) / 2.0;
        const next_geometric = @sqrt(arithmetic * geometric);
        arithmetic = next_arithmetic;
        geometric = next_geometric;
        if (arithmetic == previous) break;
    }
    return arithmetic;
}

