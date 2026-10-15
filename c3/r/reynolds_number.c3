module reynolds_number;

const double INVALID_RESULT = -1.0e300;

fn double reynolds_number(long* values, usz length) @export("reynolds_number") {
    if (values == null || length != 4) return INVALID_RESULT;
    long density = values[0];
    long velocity = values[1];
    long diameter = values[2];
    long viscosity = values[3];
    if (density < 1 || density > 1000 || velocity < -1000 || velocity > 1000 ||
        diameter < 1 || diameter > 1000 || viscosity < 1 || viscosity > 1000)
        return INVALID_RESULT;
    long speed = velocity < 0 ? -velocity : velocity;
    return (((double)density * (double)speed) * (double)diameter) / (double)viscosity;
}
