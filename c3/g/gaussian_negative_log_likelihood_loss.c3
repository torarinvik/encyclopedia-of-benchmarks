module gaussian_negative_log_likelihood_loss;
import "math";

const usz MAX_COUNT = 256;
const usz MAX_INPUT_LENGTH = 1 + 3 * MAX_COUNT;
const double INVALID_RESULT = -1.0e300;

fn double gaussian_negative_log_likelihood_loss(long* values, usz length) @export("gaussian_negative_log_likelihood_loss") {
    if (values == null || length < 4 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long count_value = values[0];
    if (count_value < 1 || count_value > MAX_COUNT) return INVALID_RESULT;
    usz count = (usz)count_value;
    if (length != 1 + 3 * count) return INVALID_RESULT;
    double total = 0.0;
    for (usz i = 0; i < count; i++) {
        long y_scaled = values[1 + i], mu_scaled = values[1 + count + i];
        long variance_nano = values[1 + 2 * count + i];
        if (y_scaled < -1000000 || y_scaled > 1000000 || mu_scaled < -1000000 || mu_scaled > 1000000 ||
            variance_nano < 1 || variance_nano > 1000000000) return INVALID_RESULT;
        double y = (double)y_scaled / 1000000.0;
        double mu = (double)mu_scaled / 1000000.0;
        double variance = (double)variance_nano / 1000000000.0;
        if (variance < 1e-6) variance = 1e-6;
        double residual = y - mu;
        double loss_var = 0.5 * math.log(variance);
        double loss_exp = 0.5 * ((residual * residual) / variance);
        total += loss_var + loss_exp;
    }
    return total / (double)count;
}
