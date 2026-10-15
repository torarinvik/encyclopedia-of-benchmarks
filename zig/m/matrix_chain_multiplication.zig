const MAX_DIMS: usize = 65;
const MAX_DIMENSION: i64 = 1000;
const MAX_CELLS: usize = MAX_DIMS * MAX_DIMS;

export fn matrix_chain_multiplication(dimensions: [*]const i64, length: usize) i64 {
    if (length > MAX_DIMS) return -1;
    for (0..length) |index| {
        if (dimensions[index] < 1 or dimensions[index] > MAX_DIMENSION) return -1;
    }
    if (length < 2) return 0;

    const matrix_count = length - 1;
    var costs: [MAX_CELLS]i64 = undefined;
    for (0..MAX_CELLS) |index| costs[index] = 0;
    for (2..matrix_count + 1) |chain_length| {
        for (0..matrix_count - chain_length + 1) |start| {
            const finish = start + chain_length - 1;
            var best: i64 = 9223372036854775807;
            for (start..finish) |split| {
                const cost = costs[start * MAX_DIMS + split]
                    + costs[(split + 1) * MAX_DIMS + finish]
                    + dimensions[start] * dimensions[split + 1] * dimensions[finish + 1];
                if (cost < best) best = cost;
            }
            costs[start * MAX_DIMS + finish] = best;
        }
    }
    return costs[matrix_count - 1];
}
