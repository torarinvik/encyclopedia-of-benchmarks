/// Convert radians to degrees using the pinned expression order.
export fn radian_to_degree(radian: f64) f64 {
    if (!(radian >= -1_000_000.0 and radian <= 1_000_000.0)) return -1.0e300;
    return radian * (180.0 / 3.141592653589793);
}
