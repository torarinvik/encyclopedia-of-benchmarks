module connectionist_temporal_classification_loss;
import "math";

const usz MAX_TIME = 32, MAX_CLASSES = 16, MAX_TARGET = 16, MAX_STATES = 33;
const usz MAX_INPUT_LENGTH = 3 + MAX_TARGET + MAX_TIME * MAX_CLASSES;
const double NEG_INF = -1.0e300, INVALID_RESULT = -1.0e300;

fn double logaddexp_value(double left, double right) {
    if (left <= NEG_INF / 2.0) return right;
    if (right <= NEG_INF / 2.0) return left;
    double larger = left > right ? left : right;
    double smaller = left > right ? right : left;
    return larger + math.log(1.0 + math.exp(smaller - larger));
}

fn double connectionist_temporal_classification_loss(long* values, usz length) @export("connectionist_temporal_classification_loss") {
    if (values == null || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long time_value = values[0], classes_value = values[1], target_value = values[2];
    if (time_value < 1 || time_value > MAX_TIME || classes_value < 2 || classes_value > MAX_CLASSES || target_value < 1 || target_value > MAX_TARGET) return INVALID_RESULT;
    usz time = (usz)time_value, classes = (usz)classes_value, target_length = (usz)target_value;
    usz probability_base = 3 + target_length;
    if (length != probability_base + time * classes) return INVALID_RESULT;
    usz repeated = 0;
    for (usz i = 0; i < target_length; i++) {
        long target = values[3 + i];
        if (target < 1 || (usz)target >= classes) return INVALID_RESULT;
        if (i > 0 && target == values[3 + i - 1]) repeated++;
    }
    if (time < target_length + repeated) return INVALID_RESULT;
    for (usz t = 0; t < time; t++) {
        long row_sum = 0;
        for (usz c = 0; c < classes; c++) {
            long p = values[probability_base + t * classes + c];
            if (p < 1 || p > 1000000) return INVALID_RESULT;
            row_sum += p;
        }
        if (row_sum != 1000000) return INVALID_RESULT;
    }
    usz states = 2 * target_length + 1;
    long[MAX_STATES] extended;
    double[MAX_STATES] previous, current;
    for (usz s = 0; s < states; s++) {
        extended[s] = s % 2 == 0 ? 0 : values[3 + s / 2];
        previous[s] = NEG_INF;
    }
    previous[0] = math.log((double)values[probability_base] / 1000000.0);
    previous[1] = math.log((double)values[probability_base + (usz)extended[1]] / 1000000.0);
    for (usz t = 1; t < time; t++) {
        for (usz s = 0; s < states; s++) {
            double incoming = previous[s];
            if (s > 0) incoming = logaddexp_value(incoming, previous[s - 1]);
            if (s > 1 && extended[s] != extended[s - 2]) incoming = logaddexp_value(incoming, previous[s - 2]);
            double p = (double)values[probability_base + t * classes + (usz)extended[s]] / 1000000.0;
            current[s] = incoming + math.log(p);
        }
        for (usz s = 0; s < states; s++) previous[s] = current[s];
    }
    return -logaddexp_value(previous[states - 1], previous[states - 2]);
}
