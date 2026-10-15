module finding_number_of_digits_in_a_number_using_log;

extern fn double floor(double value);
extern fn double log10(double value);
extern fn double fabs(double value);

const double MAX_ABS_VALUE = 1000000.0;
const double INVALID_RESULT = -1.0e300;

fn double finding_number_of_digits_in_a_number_using_log(double value)
    @export("finding_number_of_digits_in_a_number_using_log")
{
    if (!(value >= -MAX_ABS_VALUE && value <= MAX_ABS_VALUE)) return INVALID_RESULT;
    if (value == 0.0) return 0.0;
    return floor(log10(fabs(value)) + 1.0);
}
