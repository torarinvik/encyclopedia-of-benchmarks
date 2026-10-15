module archimedes_principle_of_buoyant_force;

const double INVALID_RESULT = -1.0e300;

// Buoyant force: fluid density * gravity * displaced volume.
fn double archimedes_principle_of_buoyant_force(long* values, usz length) @export("archimedes_principle_of_buoyant_force") {
    if (length != 2 || values == null) return INVALID_RESULT;
    long fluid_density = values[0];
    long volume = values[1];
    if (fluid_density < 1 || fluid_density > 1000 || volume < 1 || volume > 1000)
        return INVALID_RESULT;
    return ((double)fluid_density * 9.80665) * (double)volume;
}
