export fn square_root_with_babylonian_method(input: f64) f64 {
    if (!(input >= 1.0 and input <= 1_000_000.0)) return -1.0;
    const num: f32 = @floatCast(input);
    var a = num;
    var b: f32 = 1.0;
    const epsilon: f64 = 0.000001;
    while (@as(f64, @floatCast(a - b)) > epsilon) {
        a = (a + b) / 2.0;
        b = num / a;
    }
    return @floatCast(a);
}
