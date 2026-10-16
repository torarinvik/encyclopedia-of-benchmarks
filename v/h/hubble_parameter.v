module hubble_parameter

import math

const invalid_result = -1.0e300

@[export: 'hubble_parameter']
pub fn hubble_parameter(values &i64, length usize) f64 {
    if unsafe { values == nil } || length != 5 { return invalid_result }
    h0_x10 := unsafe { values[0] }
    radiation_ppm := unsafe { values[1] }
    matter_ppm := unsafe { values[2] }
    dark_energy_ppm := unsafe { values[3] }
    redshift_milli := unsafe { values[4] }
    if h0_x10 < -2000 || h0_x10 > 2000 || radiation_ppm < 0 || radiation_ppm > 1000000 ||
        matter_ppm < 0 || matter_ppm > 1000000 || dark_energy_ppm < 0 || dark_energy_ppm > 1000000 ||
        radiation_ppm + matter_ppm + dark_energy_ppm > 1000000 || redshift_milli < 0 || redshift_milli > 10000 { return invalid_result }
    hubble_constant := f64(h0_x10) / 10.0
    radiation_density := f64(radiation_ppm) / 1000000.0
    matter_density := f64(matter_ppm) / 1000000.0
    dark_energy := f64(dark_energy_ppm) / 1000000.0
    redshift := f64(redshift_milli) / 1000.0
    curvature := 1.0 - (matter_density + radiation_density + dark_energy)
    z1 := redshift + 1.0
    e2 := radiation_density * math.pow(z1, 4.0) + matter_density * math.pow(z1, 3.0) + curvature * math.pow(z1, 2.0) + dark_energy
    return hubble_constant * math.pow(e2, 1.0 / 2.0)
}
