// Clean-room bounded GICOV recurrence; complete applicable notice is in package LICENSE.txt.
const ELLIPSE_COUNT: usize = 7;
const MAX_POINTS: usize = 16;
const INVALID_RESULT: f64 = -1.0e300;

fn decode(raw: i64) f32 {
    @setFloatMode(.strict);
    return @as(f32, @floatFromInt(raw)) / 1_000_000.0;
}
fn addf(a: f32, b: f32) f32 { @setFloatMode(.strict); return a + b; }
fn subf(a: f32, b: f32) f32 { @setFloatMode(.strict); return a - b; }
fn mulf(a: f32, b: f32) f32 { @setFloatMode(.strict); return a * b; }
fn divf(a: f32, b: f32) f32 { @setFloatMode(.strict); return a / b; }

pub export fn rodinia_leukocyte_gicov(values: ?[*]const i64, length: usize) f64 {
    const input = values orelse return INVALID_RESULT;
    if (length < 1) return INVALID_RESULT;
    if (input[0] < 2 or input[0] > 16) return INVALID_RESULT;
    const points: usize = @intCast(input[0]);
    if (length != 1 + ELLIPSE_COUNT * points) return INVALID_RESULT;
    for (1..length) |i| if (input[i] < -1_000_000 or input[i] > 1_000_000) return INVALID_RESULT;

    var maximum: f32 = 0.0;
    for (0..ELLIPSE_COUNT) |ellipse| {
        var sum: f32 = 0.0;
        var mean: f32 = 0.0;
        var m2: f32 = 0.0;
        const base = 1 + ellipse * points;
        for (0..points) |n| {
            const p = decode(input[base + n]);
            sum = addf(sum, p);
            const delta = subf(p, mean);
            mean = addf(mean, divf(delta, @floatFromInt(n + 1)));
            m2 = addf(m2, mulf(delta, subf(p, mean)));
        }
        mean = divf(sum, @floatFromInt(points));
        const variance = divf(m2, @floatFromInt(points - 1));
        if (!(variance > 0.0)) return INVALID_RESULT;
        const score = divf(mulf(mean, mean), variance);
        if (score > maximum) maximum = score;
    }
    return @floatCast(maximum);
}
