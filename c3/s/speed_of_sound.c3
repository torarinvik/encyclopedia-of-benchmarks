module speed_of_sound;

extern fn double pow(double base, double exponent);

const double INVALID_RESULT = -1.0e300;

fn double speed_of_sound(long* values, usz length) @export("speed_of_sound") {
    if (values == null || length != 2) return INVALID_RESULT;
    long density = values[0];
    long bulk_modulus = values[1];
    if (density < 1 || density > 1000 || bulk_modulus < 1 || bulk_modulus > 1000000000)
        return INVALID_RESULT;
    return pow((double)bulk_modulus / (double)density, 0.5);
}
