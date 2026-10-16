package temperature

import "core:math"

valid_unit :: proc(unit: f64) -> bool {
    return unit == 0.0 || unit == 1.0 || unit == 2.0 || unit == 3.0 ||
        unit == 4.0 || unit == 5.0 || unit == 6.0 || unit == 7.0
}

to_kelvin :: proc(value, unit: f64) -> f64 {
    if unit == 0.0 do return value
    if unit == 1.0 do return value + 273.15
    if unit == 2.0 do return (value + 459.67) * 5.0 / 9.0
    if unit == 3.0 do return value * 5.0 / 9.0
    if unit == 4.0 do return 373.15 - value * 2.0 / 3.0
    if unit == 5.0 do return value * 100.0 / 33.0 + 273.15
    if unit == 6.0 do return value * 5.0 / 4.0 + 273.15
    return (value - 7.5) * 40.0 / 21.0 + 273.15
}

from_kelvin :: proc(kelvin, unit: f64) -> f64 {
    if unit == 0.0 do return kelvin
    if unit == 1.0 do return kelvin - 273.15
    if unit == 2.0 do return kelvin * 9.0 / 5.0 - 459.67
    if unit == 3.0 do return kelvin * 9.0 / 5.0
    if unit == 4.0 do return (373.15 - kelvin) * 3.0 / 2.0
    if unit == 5.0 do return (kelvin - 273.15) * 33.0 / 100.0
    if unit == 6.0 do return (kelvin - 273.15) * 4.0 / 5.0
    return (kelvin - 273.15) * 21.0 / 40.0 + 7.5
}

@(export)
temperature :: proc "c" (value, from_unit, to_unit: f64) -> f64 {
    if math.is_nan(value) || value < -1_000_000.0 || value > 1_000_000.0 ||
        !valid_unit(from_unit) || !valid_unit(to_unit) do return -1e300
    return from_kelvin(to_kelvin(value, from_unit), to_unit)
}
