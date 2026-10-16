module orbital_capture_area

import math

fn round_nonnegative(value f64) f64 {
    if value >= 9007199254740992.0 { return value }
    lower := math.floor(value)
    fraction := value - lower
    lower_half := math.floor(lower / 2.0)
    odd := lower - 2.0 * lower_half != 0.0
    if fraction > 0.5 || (fraction == 0.5 && odd) { return lower + 1.0 }
    return lower
}

@[export: 'orbital_capture_area']
pub fn orbital_capture_area(capture_radius f64) f64 {
    if !(capture_radius >= 0.0 && capture_radius <= 1.0e10) { return -1.0e300 }
    area := 3.14159265358979323846 * capture_radius * capture_radius
    return round_nonnegative(area)
}
