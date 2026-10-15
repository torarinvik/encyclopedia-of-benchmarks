/// Convert degrees to radians using the pinned expression order.
export fn radians(degree: f64) f64 {
    if (!(degree >= -1_000_000.0 and degree <= 1_000_000.0)) return -1.0e300;
    return degree / (180.0 / 3.141592653589793);
}
