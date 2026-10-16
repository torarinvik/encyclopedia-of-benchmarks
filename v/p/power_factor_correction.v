module power_factor_correction
import math
@[export: 'power_factor_correction']
pub fn power_factor_correction(v &i64, n usize) f64 {
    if n != 6 { return -1.0e300 }
    unsafe {
        op, voltage, frequency, power, cb, eb := v[0],v[1],v[2],v[3],v[4],v[5]
        if (op != 0 && op != 1) || voltage < 1 || voltage > 1000 || frequency < 1 || frequency > 1000 || power < -1000000 || power > 1000000 || cb < -10000 || cb > 10000 || eb < -10000 || eb > 10000 || cb == 0 || eb == 0 || (op == 1 && cb == eb) { return -1.0e300 }
        c:=f64(cb)/10000.0; e:=f64(eb)/10000.0; p:=f64(power)
        dq:=(p/c)*math.sin(math.acos(c))-(p/e)*math.sin(math.acos(e))
        if op == 0 { return dq/(2.0*math.pi*f64(frequency)*f64(voltage)*f64(voltage)) }
        return f64(voltage)*f64(voltage)/(2.0*math.pi*f64(frequency)*dq)
    }
}
