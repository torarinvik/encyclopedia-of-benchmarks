package orbital_capture_radii

import "core:math"

round_nonnegative :: proc "contextless" (value: f64) -> f64 {
    if value >= 9007199254740992.0 do return value
    lower := math.floor(value)
    fraction := value - lower
    lower_half := math.floor(lower / 2.0)
    odd := lower - 2.0 * lower_half != 0.0
    if fraction > 0.5 || (fraction == 0.5 && odd) do return lower + 1.0
    return lower
}

@(export)
orbital_capture_radii :: proc "c" (radius, mass, velocity: f64) -> f64 {
    if !(radius >= 1.0e-6 && radius <= 1.0e10) || !(mass >= 0.0 && mass <= 2.0e30) || !(velocity >= 1.0e6 && velocity <= 299792458.0) do return -1.0e300
    escape_velocity_squared := (2.0 * 6.67430e-11 * mass) / radius
    capture_radius := radius * math.sqrt(1.0 + escape_velocity_squared / (velocity * velocity))
    return round_nonnegative(capture_radius)
}
