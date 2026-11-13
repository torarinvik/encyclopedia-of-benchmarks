const std = @import("std");

const max_input_length: usize = 7;

fn exactInteger(value: f64, low: f64, high: f64) bool {
    return std.math.isFinite(value) and value >= low and value <= high and @trunc(value) == value;
}
fn rhs(id: i64, x: f64, y: f64) f64 {
    return switch (id) { 0 => y, 1 => x+y, 2 => @sin(x), else => 1.0 };
}
const Trial = struct { y5: f64, error: f64, k7: f64 };
fn trial(id: i64,x: f64,y: f64,h: f64,k1: f64) ?Trial {
    const k2=rhs(id,x+h*(1.0/5.0),y+h*((1.0/5.0)*k1));
    const k3=rhs(id,x+h*(3.0/10.0),y+h*((3.0/40.0)*k1+(9.0/40.0)*k2));
    const k4=rhs(id,x+h*(4.0/5.0),y+h*((44.0/45.0)*k1-(56.0/15.0)*k2+(32.0/9.0)*k3));
    const k5=rhs(id,x+h*(8.0/9.0),y+h*((19372.0/6561.0)*k1-(25360.0/2187.0)*k2+(64448.0/6561.0)*k3-(212.0/729.0)*k4));
    const k6=rhs(id,x+h,y+h*((9017.0/3168.0)*k1-(355.0/33.0)*k2+(46732.0/5247.0)*k3+(49.0/176.0)*k4-(5103.0/18656.0)*k5));
    const y5=y+h*((35.0/384.0)*k1+(500.0/1113.0)*k3+(125.0/192.0)*k4-(2187.0/6784.0)*k5+(11.0/84.0)*k6);
    const k7=rhs(id,x+h,y5);
    const error=h*((71.0/57600.0)*k1-(71.0/16695.0)*k3+(71.0/1920.0)*k4-(17253.0/339200.0)*k5+(22.0/525.0)*k6-(1.0/40.0)*k7);
    if (!std.math.isFinite(y5) or !std.math.isFinite(error) or !std.math.isFinite(k7)) return null;
    return .{ .y5=y5, .error=error, .k7=k7 };
}
fn integrate(id: i64, initial_y: f64, initial_x: f64, ending: f64, exponent: i64, attempts: i64) ?f64 {
    const tolerance=std.math.pow(f64,10.0,-@as(f64,@floatFromInt(exponent)));
    var x=initial_x;
    var y=initial_y;
    var h=@min((ending-initial_x)/4.0,0.25);
    var k1=rhs(id,x,y);
    for(0..@intCast(attempts)) |_| {
        const remaining=ending-x;
        if(remaining<=0.0)return y;
        const step=@min(@min(h,0.25),remaining);
        if(step<=0.0 or x+step==x)return null;
        const candidate=trial(id,x,y,step,k1) orelse return null;
        const scale=tolerance*(1.0+@max(@abs(y),@abs(candidate.y5)));
        const norm=@abs(candidate.error)/scale;
        if(!std.math.isFinite(norm))return null;
        if(norm<=1.0){x=if(step==remaining)ending else x+step;y=candidate.y5;k1=candidate.k7;if(x>=ending)return if(std.math.isFinite(y)) y else null;}
        const factor=if(norm==0.0)5.0 else 0.9*std.math.pow(f64,norm,-0.2);
        h=step*@min(5.0,@max(0.2,factor));
    }
    return null;
}

export fn dormand_prince_54_adaptive_ode(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values=input orelse return -1;
    if(input_length!=6 or input_length>max_input_length or
       !exactInteger(values[0],0,3) or !exactInteger(values[1],-1000,1000) or
       !exactInteger(values[2],-1000,1000) or !exactInteger(values[3],-1000,1000) or
       !exactInteger(values[4],8,9) or !exactInteger(values[5],64,128) or values[3]<=values[2])return -1;
    const out=output orelse return -2;
    if(output_capacity<1)return -2;
    const result=integrate(@intFromFloat(values[0]),values[1]/1000.0,values[2]/1000.0,
        values[3]/1000.0,@intFromFloat(values[4]),@intFromFloat(values[5])) orelse return -3;
    if(!std.math.isFinite(result))return -3;
    out[0]=result;
    return 1;
}
