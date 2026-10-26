module cbench_consumer_lame_mdct_short;
import "core:math";

const double PI = 3.14159265358979323846264338327950288;
const double ENWINDOW_MAX = 0.030526638;

fn bool finite_value(double value) { return value == value && value <= 1.7976931348623157e308 && value >= -1.7976931348623157e308; }

fn long cbench_consumer_lame_mdct_short(double* input, usz input_length, double* output, usz output_capacity)
    @export("cbench_consumer_lame_mdct_short") {
    if input == null || input_length == 0 || input_length > 19 return -1;
    for k: usz = 0; k < input_length; k++ {
        if !finite_value(input[k]) || input[k] < -32768.0 || input[k] > 32768.0 return -1;
    }
    if input_length != 18 return -1;
    double[36] coefficients = zeroed;
    double scale = 4.0 / 12.0;
    for i: usz = 0; i < 3; i++ {
        double w2 = math.cos(PI / 12.0 * ((double)i + 0.5)) * ENWINDOW_MAX / 32768.0 * scale;
        for m: usz = 0; m < 6; m++ {
            coefficients[6*m+i] = w2 * math.cos((PI / 48.0) * (double)(2*m+1) * (double)(4*i+14));
            coefficients[6*m+i+3] = w2 * math.cos((PI / 48.0) * (double)(2*m+1) * (double)(4*i+38));
        }
    }
    double[18] staged = zeroed;
    for m: int = 5; m >= 0; m-- {
        for l: int = 2; l >= 0; l-- {
            usz base = 6 * (usz)l;
            double sum = coefficients[6*(usz)m] * input[base];
            for i: usz = 1; i < 6; i++ sum += coefficients[6*(usz)m+i] * input[base+i];
            staged[3*(usz)m+(usz)l] = sum;
        }
    }
    if output == null || output_capacity < 18 return -2;
    for i: usz = 0; i < 18; i++ output[i] = staged[i];
    return 18;
}
