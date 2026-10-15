module finding_number_of_digits_in_a_number_using_log;

extern fn double floor(double value);
extern fn double log10(double value);

const long MAX_ABS_VALUE = 1000000;

fn long finding_number_of_digits_in_a_number_using_log(long value) @export("finding_number_of_digits_in_a_number_using_log")
{
    if (value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE) return -1;
    if (value == 0) return 0;
    double magnitude = (double)value;
    if (magnitude < 0.0) magnitude = -magnitude;
    return (long)floor(log10(magnitude) + 1.0);
}
