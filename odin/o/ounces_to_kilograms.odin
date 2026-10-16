package ounces_to_kilograms

@(export)
ounces_to_kilograms :: proc "c" (ounces: f64) -> f64 {
    if ounces < -1000000.0 || ounces > 1000000.0 do return -1e300
    return (ounces * 28.3498) / 1000.0
}
