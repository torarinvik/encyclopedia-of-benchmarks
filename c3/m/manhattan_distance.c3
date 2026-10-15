module manhattan_distance;

const double INVALID_RESULT = -1.0e300;

fn double manhattan_distance(long* values, usz length) @export("manhattan_distance") {
    if (values == null || length < 3) return INVALID_RESULT;
    long dimensions = values[0];
    if (dimensions < 1 || dimensions > 16 || length != 1 + 2 * (usz)dimensions) return INVALID_RESULT;
    long total = 0;
    for (usz index = 0; index < (usz)dimensions; index++) {
        long first = values[1 + index];
        long second = values[1 + (usz)dimensions + index];
        if (first < -1000000 || first > 1000000 || second < -1000000 || second > 1000000) return INVALID_RESULT;
        long difference = first - second;
        total += difference < 0 ? -difference : difference;
    }
    return (double)total;
}
