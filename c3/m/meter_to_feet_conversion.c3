module meter_to_feet_conversion;
const double INVALID_RESULT=-1.0e300;
fn double meter_to_feet_conversion(long* v, usz n) @export("meter_to_feet_conversion") {
    if (v == null || n != 2) return INVALID_RESULT;
    long op=v[0], units=v[1];
    if ((op != 0 && op != 1) || units < -1000000000 || units > 1000000000) return INVALID_RESULT;
    double value=(double)units/1000.0;
    if (op == 0) return value*0.3048;
    return value/0.3048;
}
