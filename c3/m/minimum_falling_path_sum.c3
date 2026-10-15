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

    long[MAX_N] costs;
    long[MAX_N] next_costs;
    for (usz column = 0; column < n; column++) costs[column] = input[1 + column];
    for (usz row = 1; row < n; row++) {
        for (usz column = 0; column < n; column++) {
            long best = costs[column];
            if (column > 0 && costs[column - 1] < best) best = costs[column - 1];
            if (column + 1 < n && costs[column + 1] < best) best = costs[column + 1];
            next_costs[column] = best + input[1 + row * n + column];
        }
        for (usz column = 0; column < n; column++) costs[column] = next_costs[column];
    }
    long minimum = costs[0];
    for (usz column = 1; column < n; column++) {
        if (costs[column] < minimum) minimum = costs[column];
    }
    return minimum;
}
