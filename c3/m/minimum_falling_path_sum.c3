module minimum_falling_path_sum;

const MAX_N = 100;
const INVALID_RESULT = -10001;

fn long minimum_falling_path_sum(long* input, usz length) @export("minimum_falling_path_sum")
{
    if (input == null || length < 1 || input[0] < 1 || input[0] > MAX_N) return INVALID_RESULT;
    usz n = (usz)input[0];
    if (length != 1 + n * n) return INVALID_RESULT;
    for (usz index = 0; index < n * n; index++) {
        if (input[1 + index] < -100 || input[1 + index] > 100) return INVALID_RESULT;
    }

    ushort[MAX_N + 2] costs;
    ushort[MAX_N] next_costs;
    costs[0] = 32768;
    costs[n + 1] = 32768;
    for (usz column = 0; column < n; column++) {
        costs[column + 1] = (ushort)(input[1 + column] + 100);
    }
    for (usz row = 1; row < n; row++) {
        for (usz column = 0; column < n; column++) {
            ushort left = costs[column];
            ushort center = costs[column + 1];
            ushort right = costs[column + 2];
            ushort left_or_center = left < center ? left : center;
            ushort best = right < left_or_center ? right : left_or_center;
            next_costs[column] = (ushort)(best + input[1 + row * n + column] + 100);
        }
        for (usz column = 0; column < n; column++) {
            costs[column + 1] = next_costs[column];
        }
    }
    ushort minimum = costs[1];
    for (usz column = 1; column < n; column++) {
        if (costs[column + 1] < minimum) minimum = costs[column + 1];
    }
    return (long)(minimum) - 100 * (long)(n);
}
