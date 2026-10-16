package cone

import "core:c"
import "core:math"

@(export)
cone :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 3 do return -1.0e300
    operation := values[0]
    radius := values[1]
    height := values[2]
    if (operation != 0 && operation != 1) || radius < 0 || radius > 1000 ||
        height < 0 || height > 1000 do return -1.0e300
    pi: f64 = 3.14159265358979323846
    radius_value := f64(radius)
    radius_squared := radius_value * radius_value
    base_area := radius_squared * pi
    if operation == 0 do return (base_area * f64(height) * 1.0) / 3.0
    height_value := f64(height)
    return base_area + pi * radius_value * math.sqrt(radius_squared + height_value * height_value)
}
