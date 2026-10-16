module dynamic_time_warping;

const long MAX_SERIES_LENGTH = 16;
const long MAX_SAMPLE_VALUE = 1000;
const double INVALID_RESULT = -1.0e300;
const double UNREACHABLE = 1.0e300;

fn double dynamic_time_warping(long* values, usz length) @export("dynamic_time_warping") {
    if (values == null || length < 3 || length > 35) return INVALID_RESULT;
    long first_length_value = values[0];
    long second_length_value = values[1];
    long band_value = values[2];
    if (first_length_value < 1 || first_length_value > MAX_SERIES_LENGTH ||
        second_length_value < 1 || second_length_value > MAX_SERIES_LENGTH) return INVALID_RESULT;
    usz first_length = (usz)first_length_value;
    usz second_length = (usz)second_length_value;
    long difference = first_length_value > second_length_value
        ? first_length_value - second_length_value : second_length_value - first_length_value;
    if (band_value < difference || band_value > MAX_SERIES_LENGTH ||
        length != 3 + first_length + second_length) return INVALID_RESULT;
    usz band = (usz)band_value;
    for (usz index = 0; index < first_length + second_length; index++) {
        if (values[3 + index] < -MAX_SAMPLE_VALUE || values[3 + index] > MAX_SAMPLE_VALUE) return INVALID_RESULT;
    }

    double[2][17] rows;
    for (usz j = 0; j <= second_length; j++) rows[0][j] = UNREACHABLE;
    rows[0][0] = 0.0;
    for (usz i = 1; i <= first_length; i++) {
        usz current = i % 2;
        usz previous = (i - 1) % 2;
        for (usz j = 0; j <= second_length; j++) rows[current][j] = UNREACHABLE;
        usz start = i > band ? i - band : 1;
        usz end = i + band < second_length ? i + band : second_length;
        for (usz j = start; j <= end; j++) {
            long difference_value = values[3 + i - 1] - values[3 + first_length + j - 1];
            if (difference_value < 0) difference_value = -difference_value;
            double best = rows[previous][j];
            if (rows[current][j - 1] < best) best = rows[current][j - 1];
            if (rows[previous][j - 1] < best) best = rows[previous][j - 1];
            rows[current][j] = (double)difference_value + best;
        }
    }
    return rows[first_length % 2][second_length];
}
