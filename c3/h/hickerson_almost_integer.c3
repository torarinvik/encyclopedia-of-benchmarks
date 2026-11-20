module hickerson_almost_integer;
import "math";

const double INVALID_RESULT = -1.0e300;

fn double hickerson_almost_integer(long* values, usz length) @export("hickerson_almost_integer") {
    if (values == null || length != 1 || values[0] < 1 || values[0] > 17) return INVALID_RESULT;
    double log_two = math.log(2.0);
    double value = 1.0 / (2.0 * log_two * log_two);
    for (long n = 2; n <= values[0]; n++) value = ((double)n / log_two) * value;
    return value;
}
