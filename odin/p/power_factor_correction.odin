package power_factor_correction
import "core:c"
import "core:math"
@(export)
power_factor_correction :: proc "c" (v: [^]i64, n: c.size_t) -> f64 {
    if v == nil || n != 6 do return -1.0e300
    op, voltage, frequency, power, cb, eb := v[0],v[1],v[2],v[3],v[4],v[5]
    if (op != 0 && op != 1) || voltage < 1 || voltage > 1000 || frequency < 1 || frequency > 1000 || power < -1000000 || power > 1000000 || cb < -10000 || cb > 10000 || eb < -10000 || eb > 10000 || cb == 0 || eb == 0 || (op == 1 && cb == eb) do return -1.0e300
    cval, eval, p := f64(cb)/10000.0, f64(eb)/10000.0, f64(power)
    dq := (p/cval)*math.sin(math.acos(cval))-(p/eval)*math.sin(math.acos(eval))
    if op == 0 do return dq/(2.0*math.PI*f64(frequency)*f64(voltage)*f64(voltage))
    return f64(voltage)*f64(voltage)/(2.0*math.PI*f64(frequency)*dq)
}
