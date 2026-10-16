module present_value_rust;

extern fn double pow(double base, double exponent);
extern fn double round(double value);

const long MAX_CASH_FLOWS = 8;
const long MAX_RATE_PPM = 1000000;
const long MAX_CASH_FLOW_MILLI = 1000000;
const usz MAX_INPUT_LENGTH = 11;
const double INVALID_RESULT = -1.0e300;

fn double present_value_rust(long* values, usz length) @export("present_value_rust") {
    if (values == null || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long count = values[0];
    long rate_ppm = values[1];
    if (count < 1 || count > MAX_CASH_FLOWS || length != (usz)count + 2 ||
        (rate_ppm != 0 && rate_ppm != MAX_RATE_PPM)) return INVALID_RESULT;

    double discount_rate = (double)rate_ppm / 1000000.0;
    double present_value = 0.0;
    for (long index = 0; index < count; index++) {
        long cash_flow_milli = values[(usz)index + 2];
        if (cash_flow_milli < -MAX_CASH_FLOW_MILLI || cash_flow_milli > MAX_CASH_FLOW_MILLI || cash_flow_milli % 125 != 0)
            return INVALID_RESULT;
        double cash_flow = (double)cash_flow_milli / 1000.0;
        present_value += cash_flow / pow(1.0 + discount_rate, (double)index);
    }
    return round(present_value * 100.0) / 100.0;
}
