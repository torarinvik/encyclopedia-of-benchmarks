const std = @import("std");
export fn power_factor_correction(v: [*]const i64, n: usize) f64 {
    if (n != 6) return -1.0e300;
    const op=v[0]; const voltage=v[1]; const frequency=v[2]; const power=v[3]; const cb=v[4]; const eb=v[5];
    if ((op != 0 and op != 1) or voltage < 1 or voltage > 1000 or frequency < 1 or frequency > 1000 or power < -1_000_000 or power > 1_000_000 or cb < -10_000 or cb > 10_000 or eb < -10_000 or eb > 10_000 or cb == 0 or eb == 0 or (op == 1 and cb == eb)) return -1.0e300;
    const c=@as(f64,@floatFromInt(cb))/10_000.0; const e=@as(f64,@floatFromInt(eb))/10_000.0; const p=@as(f64,@floatFromInt(power));
    const dq=(p/c)*@sin(@acos(c))-(p/e)*@sin(@acos(e));
    const pi: f64=3.14159265358979323846;
    if (op == 0) return dq/(2.0*pi*@as(f64,@floatFromInt(frequency))*@as(f64,@floatFromInt(voltage))*@as(f64,@floatFromInt(voltage)));
    return @as(f64,@floatFromInt(voltage))*@as(f64,@floatFromInt(voltage))/(2.0*pi*@as(f64,@floatFromInt(frequency))*dq);
}
