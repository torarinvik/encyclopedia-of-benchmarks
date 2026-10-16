const std = @import("std");
const invalid_result: f64 = -1.0e300;
fn derivative(id: i64, x: f64, y: f64) f64 { return switch (id) { 0 => y, 1 => x, 2 => x + y, 3 => (x - y) / 2.0, else => 1.0 + y * y }; }
fn fehlbergStep(id: i64, x: f64, y: f64, h: f64) ?f64 {
    const k1=h*derivative(id,x,y); const k2=h*derivative(id,x+h/4.0,y+k1/4.0);
    const k3=h*derivative(id,x+(3.0/8.0)*h,y+(3.0/32.0)*k1+(9.0/32.0)*k2);
    const k4=h*derivative(id,x+(12.0/13.0)*h,y+(1932.0/2197.0)*k1-(7200.0/2197.0)*k2+(7296.0/2197.0)*k3);
    const k5=h*derivative(id,x+h,y+(439.0/216.0)*k1-8.0*k2+(3680.0/513.0)*k3-(845.0/4104.0)*k4);
    const k6=h*derivative(id,x+h/2.0,y-(8.0/27.0)*k1+2.0*k2-(3544.0/2565.0)*k3+(1859.0/4104.0)*k4-(11.0/40.0)*k5);
    const out=y+(16.0/135.0)*k1+(6656.0/12825.0)*k3+(28561.0/56430.0)*k4-(9.0/50.0)*k5+(2.0/55.0)*k6;
    if (!std.math.isFinite(k1) or !std.math.isFinite(k2) or !std.math.isFinite(k3) or !std.math.isFinite(k4) or !std.math.isFinite(k5) or !std.math.isFinite(k6) or !std.math.isFinite(out)) return null;
    return out;
}
export fn runge_kutta_fehlberg_45(input: [*c]const i64, length: usize) f64 {
    if (input == null or length != 5) return invalid_result;
    const fid, ym, xm, hm, em = .{input[0],input[1],input[2],input[3],input[4]};
    if (fid<0 or fid>4 or ym< -1000000 or ym>1000000 or xm< -1000000 or xm>1000000 or em< -1000000 or em>1000000 or hm<10000 or hm>250000 or em<=xm) return invalid_result;
    const y0=@as(f64,@floatFromInt(ym))/1000000.0; var x=@as(f64,@floatFromInt(xm))/1000000.0;
    const h=@as(f64,@floatFromInt(hm))/1000000.0; const ending=@as(f64,@floatFromInt(em))/1000000.0;
    if(fid==4 and (x<0.0 or y0>0.0))return invalid_result;
    const ratio=(ending-x)/h; const steps:usize=@intFromFloat(ratio); if(steps<1 or steps>64)return invalid_result;
    var y=y0; for(0..steps)|_|{y=fehlbergStep(fid,x,y,h) orelse return invalid_result;x=h+x;if(!std.math.isFinite(x))return invalid_result;} return y;
}
