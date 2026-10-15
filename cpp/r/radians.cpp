// Convert degrees to radians using the pinned expression order.

extern "C" double radians(double degree) noexcept {
    if (!(degree >= -1000000.0 && degree <= 1000000.0)) return -1.0e300;
    return degree / (180.0 / 3.141592653589793);
}
