/// Net present value with source-ordered binary64 terms.
const std = @import("std");
const INVALID: f64 = -1e300;
pub export fn npv(input: [*c]const i64, length: usize) f64 {
    if (input == null or length < 2) return INVALID;
    const n64=input[0];const rate_bp=input[1];
    if (n64 < 0 or n64 > 64 or rate_bp < 0 or rate_bp > 1000) return INVALID;
    const n: usize=@intCast(n64);if (length != n+2) return INVALID;
    const cash_flows=input[2..][0..n];
    for (cash_flows) |flow| { if (flow < -1_000_000 or flow > 1_000_000) return INVALID; }
    const rate=@as(f64,@floatFromInt(rate_bp))/10000.0;
    var total: f64=0.0;
    for (cash_flows,0..) |flow,t| {
        const term=@as(f64,@floatFromInt(flow))/std.math.pow(f64,1.0+rate,@floatFromInt(t));
        total=total+term;
    }
    return total;
}
