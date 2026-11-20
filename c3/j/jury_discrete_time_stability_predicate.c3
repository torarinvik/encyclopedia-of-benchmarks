module jury_discrete_time_stability_predicate;

fn long jury_discrete_time_stability_predicate(long* input, usz length)
    @export("jury_discrete_time_stability_predicate") {
    if (input == null || length < 1 || length > 7) return -1;
    long degree = input[0];
    if (degree < 1 || degree > 4 || length != (degree + 2).usz()) return -1;

    long[5] coefficients = {0, 0, 0, 0, 0};
    for (long index = 0; index <= degree; index += 1) {
        long value = input[(index + 1).usz()];
        if (value < -9 || value > 9 || (index == 0 && value == 0)) return -1;
        coefficients[index.usz()] = value;
    }
    if (coefficients[0] < 0) {
        for (long index = 0; index <= degree; index += 1) coefficients[index.usz()] = -coefficients[index.usz()];
    }

    long at_one = 0;
    long at_minus_one = 0;
    for (long index = 0; index <= degree; index += 1) {
        at_one += coefficients[index.usz()];
        if ((degree - index) % 2 == 0) at_minus_one += coefficients[index.usz()];
        else at_minus_one -= coefficients[index.usz()];
    }
    if (at_one <= 0 || ((degree % 2 == 0 && at_minus_one <= 0) || (degree % 2 != 0 && at_minus_one >= 0))) return 0;

    long[5] row = {0, 0, 0, 0, 0};
    long[5] reduced = {0, 0, 0, 0, 0};
    for (long index = 0; index <= degree; index += 1) row[index.usz()] = coefficients[index.usz()];
    for (long current_degree = degree; current_degree >= 1; current_degree -= 1) {
        long trailing = row[current_degree.usz()];
        long trailing_magnitude = trailing < 0 ? -trailing : trailing;
        if (row[0] <= trailing_magnitude) return 0;
        if (current_degree == 1) break;
        for (long index = 0; index < current_degree; index += 1) {
            reduced[index.usz()] = row[0] * row[index.usz()] - trailing * row[(current_degree - index).usz()];
        }
        for (long index = 0; index < current_degree; index += 1) row[index.usz()] = reduced[index.usz()];
    }
    return 1;
}
