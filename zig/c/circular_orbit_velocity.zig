export fn circular_orbit_velocity(v: [*c]const f64, n: usize, output: [*c]f64, capacity: usize) i64 {
    if (v==null or n!=2) return -1;
    const mass=v[0]; const radius=v[1];
    if (mass!=mass or radius!=radius or mass<1.0e-12 or mass>1.0e25 or radius<1.0e-12 or radius>1.0e12) return -1;
    if (output==null or capacity<1) return -2;
    output[0]=@sqrt(6.67430e-11*mass/radius);
    return 1;
}
