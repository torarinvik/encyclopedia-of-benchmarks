module kelvin_to_celsius;

fn double kelvin_to_celsius(double temperature_in_k) @export("kelvin_to_celsius") {
    if (!(temperature_in_k >= 0.0 && temperature_in_k <= 1000000.0)) return -1.0;
    double absolute_zero_in_c = -273.15;
    return temperature_in_k + absolute_zero_in_c;
}
