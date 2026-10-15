module average_margin_ranking_loss;

const usz MAX_LENGTH = 256;
const double INVALID_RESULT = -1.0e300;

fn double average_margin_ranking_loss(long* values, usz length) @export("average_margin_ranking_loss") {
    if (values == null || length < 5 || length > 2 * MAX_LENGTH + 3) return INVALID_RESULT;
    long count_value = values[0];
    long margin_value = values[1];
    long label_value = values[2];
    if (count_value < 1 || count_value > (long)MAX_LENGTH || length != 2 * (usz)count_value + 3 ||
        margin_value < 0 || margin_value > 1000 || (label_value != 1 && label_value != -1)) return INVALID_RESULT;
    usz count = (usz)count_value;
    double total = 0.0;
    for (usz index = 0; index < count; index++) {
        long first = values[index + 3];
        long second = values[index + 3 + count];
        if (first < -1000 || first > 1000 || second < -1000 || second > 1000) return INVALID_RESULT;
        double loss = (double)margin_value - (double)label_value * ((double)first - (double)second);
        if (loss > 0.0) total += loss;
    }
    return total / (double)count;
}
