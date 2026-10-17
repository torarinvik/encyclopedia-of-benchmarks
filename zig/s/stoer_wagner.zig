const MAX_N: usize = 16;
const MAX_INPUT_VALUES: usize = 257;
const MAX_WEIGHT: i64 = 1_000_000;

export fn stoer_wagner(input: [*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_INPUT_VALUES) return -1;
    const n_value = input[0];
    if (n_value < 2 or n_value > 16) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + n * n) return -1;

    var graph = [_][MAX_N]i64{[_]i64{0} ** MAX_N} ** MAX_N;
    for (0..n) |row| {
        for (0..n) |column| {
            const weight = input[1 + row * n + column];
            if (weight < 0 or weight > MAX_WEIGHT) return -1;
            graph[row][column] = weight;
        }
    }
    for (0..n) |row| {
        if (graph[row][row] != 0) return -1;
        for (row + 1..n) |column| {
            if (graph[row][column] != graph[column][row]) return -1;
        }
    }

    var merged = [_]bool{false} ** MAX_N;
    var min_cut: i64 = 120_000_001;
    for (0..(n - 1)) |phase| {
        var in_set = [_]bool{false} ** MAX_N;
        var weights = [_]i64{0} ** MAX_N;
        var previous: ?usize = null;
        var last: ?usize = null;
        for (0..(n - phase)) |_| {
            var current: ?usize = null;
            var max_weight: i64 = -1;
            for (0..n) |vertex| {
                if (!merged[vertex] and !in_set[vertex] and weights[vertex] > max_weight) {
                    max_weight = weights[vertex];
                    current = vertex;
                }
            }
            const current_vertex = current orelse break;
            in_set[current_vertex] = true;
            previous = last;
            last = current_vertex;
            for (0..n) |vertex| {
                if (!merged[vertex] and !in_set[vertex]) {
                    weights[vertex] += graph[current_vertex][vertex];
                }
            }
        }
        const last_vertex = last orelse return -1;
        const previous_vertex = previous orelse return -1;
        if (weights[last_vertex] < min_cut) min_cut = weights[last_vertex];
        for (0..n) |vertex| {
            graph[previous_vertex][vertex] += graph[last_vertex][vertex];
            graph[vertex][previous_vertex] = graph[previous_vertex][vertex];
        }
        merged[last_vertex] = true;
    }
    return min_cut;
}
