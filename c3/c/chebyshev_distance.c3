module chebyshev_distance;

fn long chebyshev_distance(long* values, usz length) @export("chebyshev_distance") {
    if (length < 3) return -1;
    long dimension_value = values[0];
    if (dimension_value < 1 || dimension_value > 128) return -1;
    usz dimension = (usz)dimension_value;
    if (length != 1 + 2 * dimension) return -1;
    long maximum = 0;
    for (usz i = 0; i < dimension; i++) {
        long a = values[1 + i];
        long b = values[1 + dimension + i];
        if (a < -1000000000 || a > 1000000000 || b < -1000000000 || b > 1000000000) return -1;
        long difference = a - b;
        if (difference < 0) difference = -difference;
        if (difference > maximum) maximum = difference;
    }
    return maximum;
}
