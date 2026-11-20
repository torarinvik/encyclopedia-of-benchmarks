module number_of_ways_of_cutting_a_pizza;

const usz MAX_INPUT = 39;
const long MODULUS = 1000000007;

fn long number_of_ways_of_cutting_a_pizza(long *input, usz length)
    @export("number_of_ways_of_cutting_a_pizza") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long rows_value = input[0], columns_value = input[1], cuts_value = input[2];
    if (rows_value < 1 || rows_value > 6 || columns_value < 1 || columns_value > 6 ||
        cuts_value < 0 || cuts_value > 5 ||
        length != (usz)3 + (usz)(rows_value * columns_value)) return -1;
    usz rows = (usz)rows_value, columns = (usz)columns_value, cuts = (usz)cuts_value;
    long[49] suffix, previous, current;
    for (usz index = 0; index < 49; index++) {
        suffix[index] = 0; previous[index] = 0; current[index] = 0;
    }
    for (usz row = 0; row < rows; row++) {
        for (usz column = 0; column < columns; column++) {
            long cell = input[3 + row * columns + column];
            if (cell != 0 && cell != 1) return -1;
        }
    }
    for (usz row = rows; row > 0; row--) {
        usz r = row - 1;
        for (usz column = columns; column > 0; column--) {
            usz c = column - 1;
            long cell = input[3 + r * columns + c];
            usz at = r * 7 + c;
            suffix[at] = cell + suffix[(r + 1) * 7 + c] + suffix[r * 7 + c + 1]
                - suffix[(r + 1) * 7 + c + 1];
        }
    }
    for (usz row = 0; row < rows; row++)
        for (usz column = 0; column < columns; column++)
            previous[row * 7 + column] = suffix[row * 7 + column] > 0 ? 1 : 0;

    for (usz remaining = 1; remaining <= cuts; remaining++) {
        for (usz index = 0; index < 49; index++) current[index] = 0;
        for (usz row = rows; row > 0; row--) {
            usz r = row - 1;
            for (usz column = columns; column > 0; column--) {
                usz c = column - 1, origin = r * 7 + c;
                long ways = 0;
                for (usz cut = r + 1; cut < rows; cut++)
                    if (suffix[origin] - suffix[cut * 7 + c] > 0)
                        ways += previous[cut * 7 + c];
                for (usz cut = c + 1; cut < columns; cut++)
                    if (suffix[origin] - suffix[r * 7 + cut] > 0)
                        ways += previous[r * 7 + cut];
                current[origin] = ways % MODULUS;
            }
        }
        for (usz index = 0; index < 49; index++) previous[index] = current[index];
    }
    return previous[0];
}
