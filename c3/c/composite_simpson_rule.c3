module composite_simpson_rule;

extern fn double sqrt(double value);
extern fn double log(double value);
extern fn double exp(double value);
extern fn double floor(double value);
extern fn double pow(double base, double exponent);

const double INVALID_RESULT = -1.0;
const int32 MAX_INTERVALS = 128;

fn double sample(int32 function_id, double x) {
    if (function_id == 0) return sqrt(x) + log(x);
    if (function_id == 1) return exp(-x) * (4.0 - pow(x, 2.0));
    if (function_id == 2) return sqrt(2.0 * pow(x, 3.0) + 3.0);
    return x + log(2.0 * x + 1.0);
}

fn double composite_simpson_rule(double intervals_input, double function_id_input) @export("composite_simpson_rule") {
    if (intervals_input != intervals_input || function_id_input != function_id_input ||
        intervals_input < 2.0 || intervals_input > MAX_INTERVALS ||
        function_id_input < 0.0 || function_id_input > 3.0 ||
        intervals_input != floor(intervals_input) || function_id_input != floor(function_id_input)) return INVALID_RESULT;
    int32 intervals = int32(intervals_input);
    if (intervals % 2 != 0) return INVALID_RESULT;
    int32 function_id = int32(function_id_input);
    double h = 2.0 / (double)intervals;
    double x = 1.0;
    double sum = 0.0;
    for (int32 i = 0; i <= intervals; i++) {
        double y = sample(function_id, x);
        double weight = (i == 0 || i == intervals) ? 1.0 : ((i % 2) == 1 ? 4.0 : 2.0);
        sum += weight * y;
        x += h;
    }
    return sum * (h / 3.0);
}
