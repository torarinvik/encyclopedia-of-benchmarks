const std = @import("std");

const max_input_length: usize = 5;

fn exactInteger(value: f64, low: f64, high: f64) bool {
    return std.math.isFinite(value) and value >= low and value <= high and @trunc(value) == value;
}

fn integrand(id: i64, x: f64) f64 {
    return switch (id) {
        0 => @exp(x),
        1 => x*x*x*x*x,
        2 => 1.0/(1.0+x*x),
        else => @cos(x),
    };
}

fn compute(id: i64, a: f64, b: f64, levels: i64) f64 {
    if (a == b) return 0.0;
    var previous = [_]f64{0.0} ** 9;
    previous[0] = (b-a)*(integrand(id,a)+integrand(id,b))*0.5;
    var level: i64 = 1;
    while (level <= levels) : (level += 1) {
        const interval_count: usize = @as(usize, 1) << @intCast(level);
        const spacing = (b-a)/@as(f64,@floatFromInt(interval_count));
        var added: f64 = 0.0;
        var index: usize = 1;
        while (index < interval_count) : (index += 2) {
            added += integrand(id,a+@as(f64,@floatFromInt(index))*spacing);
        }
        var current = [_]f64{0.0} ** 9;
        current[0] = previous[0]*0.5+spacing*added;
        var factor: f64 = 4.0;
        var order: usize = 1;
        while (order <= @as(usize,@intCast(level))) : (order += 1) {
            current[order] = current[order-1]+(current[order-1]-previous[order-1])/(factor-1.0);
            factor *= 4.0;
        }
        previous = current;
    }
    return previous[@intCast(levels)];
}

export fn romberg_integration(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length != 4 or input_length > max_input_length or
        !exactInteger(values[0],0,3) or !exactInteger(values[1],-1_000_000,1_000_000) or
        !exactInteger(values[2],-1_000_000,1_000_000) or !exactInteger(values[3],3,8)) return -1;
    const id: i64 = @intFromFloat(values[0]);
    const a_micro: i64 = @intFromFloat(values[1]);
    const b_micro: i64 = @intFromFloat(values[2]);
    const levels: i64 = @intFromFloat(values[3]);
    if (a_micro > b_micro) return -1;
    const out = output orelse return -2;
    if (output_capacity < 1) return -2;
    const result = compute(id,@as(f64,@floatFromInt(a_micro))/1_000_000.0,
        @as(f64,@floatFromInt(b_micro))/1_000_000.0,levels);
    if (!std.math.isFinite(result)) return -1;
    out[0] = result;
    return 1;
}
