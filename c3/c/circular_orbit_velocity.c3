module circular_orbit_velocity;
extern fn double sqrt(double value);

fn long circular_orbit_velocity(double* v, usz n, double* out, usz cap) @export("circular_orbit_velocity") {
    if (v==null || n!=2 || v[0]!=v[0] || v[1]!=v[1] || v[0]<1.0e-12 || v[0]>1.0e25 || v[1]<1.0e-12 || v[1]>1.0e12) return -1;
    if (out==null || cap<1) return -2;
    out[0]=sqrt(6.67430e-11*v[0]/v[1]);
    return 1;
}
