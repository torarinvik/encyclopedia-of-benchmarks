package meter_to_feet_conversion
import "core:c"
@(export)
meter_to_feet_conversion :: proc "c" (v: [^]i64, n: c.size_t) -> f64 {
    if v == nil || n != 2 do return -1.0e300
    op, units := v[0],v[1]
    if (op != 0 && op != 1) || units < -1000000000 || units > 1000000000 do return -1.0e300
    value := f64(units)/1000.0
    if op == 0 do return value*0.3048
    return value/0.3048
}
