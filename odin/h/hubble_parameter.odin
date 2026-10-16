package hubble_parameter

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300
MAX_DENSITY_PPM :: i64(1000000)

@(export)
hubble_parameter :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 5 do return INVALID_RESULT
    h0_x10, radiation_ppm, matter_ppm, dark_energy_ppm, redshift_milli := values[0], values[1], values[2], values[3], values[4]
    if h0_x10 < -2000 || h0_x10 > 2000 || radiation_ppm < 0 || radiation_ppm > MAX_DENSITY_PPM ||
        matter_ppm < 0 || matter_ppm > MAX_DENSITY_PPM || dark_energy_ppm < 0 || dark_energy_ppm > MAX_DENSITY_PPM ||
        radiation_ppm + matter_ppm + dark_energy_ppm > MAX_DENSITY_PPM || redshift_milli < 0 || redshift_milli > 10000 do return INVALID_RESULT
    hubble_constant := f64(h0_x10) / 10.0
    radiation_density := f64(radiation_ppm) / 1000000.0
    matter_density := f64(matter_ppm) / 1000000.0
    dark_energy := f64(dark_energy_ppm) / 1000000.0
    redshift := f64(redshift_milli) / 1000.0
    curvature := 1.0 - (matter_density + radiation_density + dark_energy)
    z1 := redshift + 1.0
    e2 := radiation_density * math.pow_f64(z1, 4.0) + matter_density * math.pow_f64(z1, 3.0) + curvature * math.pow_f64(z1, 2.0) + dark_energy
    return hubble_constant * math.pow_f64(e2, 1.0 / 2.0)
}
