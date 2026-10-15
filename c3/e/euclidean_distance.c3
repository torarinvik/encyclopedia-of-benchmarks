module euclidean_distance;
const usz MAX_DIMENSION = 128;
const double INVALID_RESULT = -1.0e300;
extern fn double sqrt(double value);

fn double euclidean_distance(long* values, usz length) @export("euclidean_distance") {
    if (values == null || length < 1) return INVALID_RESULT;
    long dimension = values[0];
    if (dimension < 0 || dimension > (long)MAX_DIMENSION || length != 1 + 2 * (usz)dimension) {
        return INVALID_RESULT;
    }
    double sum_of_squares = 0.0;
    for (usz i = 0; i < (usz)dimension; i++) {
        long first = values[1 + i];
        long second = values[1 + (usz)dimension + i];
        if (first < -1000000 || first > 1000000 || second < -1000000 || second > 1000000) {
            return INVALID_RESULT;
        }
        double difference = (double)first - (double)second;
        sum_of_squares += difference * difference;
    }
    return sqrt(sum_of_squares);
}
