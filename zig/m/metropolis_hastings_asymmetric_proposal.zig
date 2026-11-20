const max_states: i64 = 8;
const max_steps: i64 = 64;
const max_input: usize = 267;
const max_output: usize = 65;

export fn metropolis_hastings_asymmetric_proposal(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const steps64 = input[1];
    const initial64 = input[2];
    if (n64 < 2 or n64 > max_states or steps64 < 0 or steps64 > max_steps or
        initial64 < 0 or initial64 >= n64) return -1;
    const n: usize = @intCast(n64);
    const steps: usize = @intCast(steps64);
    const weights_start: usize = 3;
    const matrix_start = weights_start + n;
    const proposals_start = matrix_start + n*n;
    const draws_start = proposals_start + steps;
    if (length != draws_start + 2*steps) return -1;
    for (0..n) |state| {
        const weight = input[weights_start + state];
        if (weight < 1 or weight > 1024) return -1;
    }
    for (0..n) |row| {
        var row_sum: i64 = 0;
        for (0..n) |column| {
            const q = input[matrix_start + row*n + column];
            if (q < 0 or q > 1024) return -1;
            row_sum += q;
        }
        if (row_sum != 1024) return -1;
    }

    var staged = [_]u8{0} ** max_output;
    var current: usize = @intCast(initial64);
    staged[0] = @intCast(current);
    for (0..steps) |step| {
        const proposal64 = input[proposals_start + step];
        const draw_num = input[draws_start + 2*step];
        const draw_den = input[draws_start + 2*step + 1];
        if (proposal64 < 0 or proposal64 >= n64 or draw_den < 1 or draw_den > 1024 or
            draw_num < 0 or draw_num >= draw_den) return -1;
        const proposal: usize = @intCast(proposal64);
        const forward = input[matrix_start + current*n + proposal];
        if (forward == 0) return -1;
        const reverse = input[matrix_start + proposal*n + current];
        const numerator = input[weights_start + proposal] * reverse;
        const denominator = input[weights_start + current] * forward;
        if (numerator >= denominator or draw_num*denominator < draw_den*numerator) {
            current = proposal;
        }
        staged[step + 1] = @intCast(current);
    }
    const needed = steps + 1;
    if (output_opt == null or capacity < needed) return -2;
    const output = output_opt.?;
    for (0..needed) |index| output[index] = staged[index];
    return @intCast(needed);
}
