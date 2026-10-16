module pythagoras;
extern fn double sqrt(double value);
fn double pythagoras(long* v, usz n) @export("pythagoras") {
    if (v == null || n != 6) return -1.0e300;
    for (usz i = 0; i < 6; i += 1) if (v[i] < -1000000 || v[i] > 1000000) return -1.0e300;
    double dx = (v[3] - v[0]).double();
    double dy = (v[4] - v[1]).double();
    double dz = (v[5] - v[2]).double();
    return sqrt(dx * dx + dy * dy + dz * dz);
}
