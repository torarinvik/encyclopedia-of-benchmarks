module cherry_pickup_ii;

const usz MAX_DIM = 6, MAX_INPUT = 39;

fn long cherry_pickup_ii(long* input, usz length) @export("cherry_pickup_ii") {
    if (input == null || length < 6 || length > MAX_INPUT) return -1;
    long rows_value = input[0], columns_value = input[1];
    if (rows_value < 2 || rows_value > (long)MAX_DIM || columns_value < 2 || columns_value > (long)MAX_DIM) return -1;
    usz rows = (usz)rows_value, columns = (usz)columns_value;
    if (length != 2 + rows * columns) return -1;
    for (usz i = 0; i < rows * columns; ++i) if (input[2 + i] < 0 || input[2 + i] > 100) return -1;

    long[MAX_DIM * MAX_DIM] previous = {}, current = {};
    for (usz i = 0; i < MAX_DIM * MAX_DIM; ++i) previous[i] = -1;
    previous[columns - 1] = input[2] + input[2 + columns - 1];
    for (usz row = 1; row < rows; ++row) {
        for (usz i = 0; i < MAX_DIM * MAX_DIM; ++i) current[i] = -1;
        for (usz left = 0; left < columns; ++left) {
            for (usz right = 0; right < columns; ++right) {
                long score = previous[left * columns + right];
                if (score < 0) continue;
                for (long dl = -1; dl <= 1; ++dl) {
                    long next_left_value = (long)left + dl;
                    if (next_left_value < 0 || next_left_value >= (long)columns) continue;
                    usz next_left = (usz)next_left_value;
                    for (long dr = -1; dr <= 1; ++dr) {
                        long next_right_value = (long)right + dr;
                        if (next_right_value < 0 || next_right_value >= (long)columns) continue;
                        usz next_right = (usz)next_right_value;
                        long candidate = score + input[2 + row * columns + next_left];
                        if (next_left != next_right) candidate += input[2 + row * columns + next_right];
                        usz slot = next_left * columns + next_right;
                        if (candidate > current[slot]) current[slot] = candidate;
                    }
                }
            }
        }
        for (usz i = 0; i < MAX_DIM * MAX_DIM; ++i) previous[i] = current[i];
    }
    long answer = -1;
    for (usz left = 0; left < columns; ++left)
        for (usz right = 0; right < columns; ++right)
            if (previous[left * columns + right] > answer) answer = previous[left * columns + right];
    return answer;
}
