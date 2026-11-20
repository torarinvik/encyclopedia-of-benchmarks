module routh_hurwitz_stability_predicate;

fn long routh_hurwitz_stability_predicate(long* input, usz length)
    @export("routh_hurwitz_stability_predicate") {
    if (input == null || length < 1 || length > 7) return -1;
    long degree = input[0];
    if (degree < 1 || degree > 4 || length != (degree + 2).usz()) return -1;

    long[5] coefficients = {0, 0, 0, 0, 0};
    for (long index = 0; index <= degree; index += 1) {
        long value = input[(index + 1).usz()];
        if (value < -3 || value > 3 || (index == 0 && value <= 0)) return -1;
        coefficients[index.usz()] = value;
    }

    usz width = (degree + 2).usz() / 2;
    long[15] table = {0};
    for (usz column = 0; column < width; column += 1) {
        usz even_index = 2 * column;
        usz odd_index = even_index + 1;
        if (even_index <= degree.usz()) table[column] = coefficients[even_index];
        if (odd_index <= degree.usz()) table[3 + column] = coefficients[odd_index];
    }

    bool row_one_zero = true;
    for (usz column = 0; column < width; column += 1) {
        if (table[3 + column] != 0) row_one_zero = false;
    }
    if (row_one_zero || table[3] <= 0) return 0;

    for (usz row = 2; row <= degree.usz(); row += 1) {
        if (table[3 * (row - 1)] <= 0) return 0;
        bool all_zero = true;
        for (usz column = 0; column < width; column += 1) {
            long upper_next = column + 1 < width ? table[3 * (row - 2) + column + 1] : 0;
            long lower_next = column + 1 < width ? table[3 * (row - 1) + column + 1] : 0;
            table[3 * row + column] = table[3 * (row - 1)] * upper_next
                                      - table[3 * (row - 2)] * lower_next;
            if (table[3 * row + column] != 0) all_zero = false;
        }
        if (all_zero || table[3 * row] <= 0) return 0;
    }
    return 1;
}
