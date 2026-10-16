module saddleback_search;

fn long saddleback_search(long* values, usz length) @export("saddleback_search") {
    if (values == null || length < 3) return -1;
    long rows_value = values[0], columns_value = values[1], target = values[2];
    if (rows_value <= 0 || rows_value > 32 ||
        columns_value <= 0 || columns_value > 32 ||
        target < -2147483648 || target > 2147483647) return -1;
    usz rows = (usz)rows_value, columns = (usz)columns_value;
    usz cells = rows * columns;
    if (length != 3 + cells) return -1;
    long* matrix = values + 3;
    for (usz index = 0; index < cells; index++) {
        if (matrix[index] < -2147483648 || matrix[index] > 2147483647) return -1;
    }

    usz row = 0, column = columns - 1;
    while (row < rows) {
        long value = matrix[row * columns + column];
        if (value == target) return (long)(row * columns + column + 1);
        if (value < target) {
            row++;
        } else if (column == 0) {
            break;
        } else {
            column--;
        }
    }
    return 0;
}
