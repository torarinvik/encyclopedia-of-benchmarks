module power_factor_correction;
const double INVALID_RESULT = -1.0e300;
extern fn double acos(double value);
extern fn double sin(double value);
fn double power_factor_correction(long* v, usz n) @export("power_factor_correction") {
    if (v == null || n != 6) return INVALID_RESULT;
    long op=v[0], voltage=v[1], frequency=v[2], power=v[3], cb=v[4], eb=v[5];
    if ((op != 0 && op != 1) || voltage < 1 || voltage > 1000 || frequency < 1 || frequency > 1000 || power < -1000000 || power > 1000000 || cb < -10000 || cb > 10000 || eb < -10000 || eb > 10000 || cb == 0 || eb == 0 || (op == 1 && cb == eb)) return INVALID_RESULT;
    double c=(double)cb/10000.0, e=(double)eb/10000.0, p=(double)power;
    double dq=(p/c)*sin(acos(c))-(p/e)*sin(acos(e));
    double denom=2.0*3.14159265358979323846*(double)frequency*(double)voltage*(double)voltage;
    if (op == 0) return dq/denom;
    return ((double)voltage*(double)voltage)/(2.0*3.14159265358979323846*(double)frequency*dq);
}
