module length_conversion;

fn double meters_per_unit(int32 unit) {
    if (unit == 0) return 0.001;
    if (unit == 1) return 0.01;
    if (unit == 2) return 1.0;
    return 1000.0;
}

fn double length_conversion(double value, double from_unit_input, double to_unit_input)
    @export("length_conversion") {
    if (value != value || value < -1000000.0 || value > 1000000.0) return -1e300;
    if (!((from_unit_input == 0.0) || (from_unit_input == 1.0) || (from_unit_input == 2.0) || (from_unit_input == 3.0)) ||
        !((to_unit_input == 0.0) || (to_unit_input == 1.0) || (to_unit_input == 2.0) || (to_unit_input == 3.0))) return -1e300;
    int32 from_unit = (int32)from_unit_input;
    int32 to_unit = (int32)to_unit_input;
    return (value * meters_per_unit(from_unit)) / meters_per_unit(to_unit);
}
