// Convert radians to degrees using the pinned expression order.

extern "C" double radian_to_degree(double radian) noexcept {
    if (!(radian >= -1000000.0 && radian <= 1000000.0)) return -1.0e300;
    return radian * (180.0 / 3.141592653589793);
}
