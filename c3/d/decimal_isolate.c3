module decimal_isolate;

fn double decimal_isolate(double input) @export("decimal_isolate") {
    if (!(input > 0.0 && input <= 999999.0)) return -1.0;
    double scaled_value = input * 10000.0;
    long scaled = (long)scaled_value;
    if ((double)scaled != scaled_value || (double)scaled / 10000.0 != input ||
        scaled % 625 != 0 || scaled % 10000 == 0) return -1.0;
    return (double)(scaled % 10000) / 10000.0;
}
