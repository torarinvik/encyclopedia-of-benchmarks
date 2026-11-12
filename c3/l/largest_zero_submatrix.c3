module largest_zero_submatrix;

const MAX_ROWS = 16;
const MAX_COLUMNS = 16;

fn long largest_zero_submatrix(long* input, usz length) @export("largest_zero_submatrix") {
    if (input == null || length < 2 || length > 259) return -1;
    long rows_value = input[0], columns_value = input[1];
    if (rows_value < 1 || rows_value > MAX_ROWS || columns_value < 1 || columns_value > MAX_COLUMNS) return -1;
    usz rows = (usz)rows_value, columns = (usz)columns_value;
    if (length != 2 + rows * columns) return -1;
    for (usz index = 2; index < length; index++)
        if (input[index] != 0 && input[index] != 1) return -1;

    long[MAX_COLUMNS] last_one = {};
    int[MAX_COLUMNS] left = {}, right = {}, stack = {};
    for (usz column = 0; column < columns; column++) last_one[column] = -1;
    long best = 0;
    for (usz row = 0; row < rows; row++) {
        for (usz column = 0; column < columns; column++)
            if (input[2 + row * columns + column] == 1) last_one[column] = (long)row;

        usz top = 0;
        for (usz column = 0; column < columns; column++) {
            while (top > 0 && last_one[(usz)stack[top - 1]] <= last_one[column]) top--;
            left[column] = top == 0 ? -1 : stack[top - 1];
            stack[top++] = (int)column;
        }
        top = 0;
        for (usz cursor = columns; cursor > 0; cursor--) {
            usz column = cursor - 1;
            while (top > 0 && last_one[(usz)stack[top - 1]] <= last_one[column]) top--;
            right[column] = top == 0 ? (int)columns : stack[top - 1];
            stack[top++] = (int)column;
        }
        for (usz column = 0; column < columns; column++) {
            long height = (long)row - last_one[column];
            long width = right[column] - left[column] - 1;
            long area = height * width;
            if (area > best) best = area;
        }
    }
    return best;
}
