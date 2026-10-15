// Convert bounded lengths between millimeters, centimeters, meters, and kilometers.
namespace {
double meters_per_unit(int unit) noexcept {
    switch (unit) {
        case 0: return 0.001;
        case 1: return 0.01;
        case 2: return 1.0;
        default: return 1000.0;
    }
}
}

extern "C" double length_conversion(double value, double from_unit_input, double to_unit_input) noexcept {
    if (value != value || value < -1000000.0 || value > 1000000.0) return -1e300;
    if (!((from_unit_input == 0.0) || (from_unit_input == 1.0) ||
          (from_unit_input == 2.0) || (from_unit_input == 3.0)) ||
        !((to_unit_input == 0.0) || (to_unit_input == 1.0) ||
          (to_unit_input == 2.0) || (to_unit_input == 3.0))) return -1e300;
    const int from_unit = static_cast<int>(from_unit_input);
    const int to_unit = static_cast<int>(to_unit_input);
    return (value * meters_per_unit(from_unit)) / meters_per_unit(to_unit);
}
