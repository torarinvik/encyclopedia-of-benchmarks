const MAX_N = 10_000;
const OUTPUT_COUNT = 9;

export fn partialsums(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length != 1) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (!std.math.isFinite(n_value) or @trunc(n_value) != n_value or n_value < 1.0 or n_value > MAX_N) return -1;
    const n: usize = @intFromFloat(n_value);
    var geometric: f64 = 0.0;
    var inverse_sqrt: f64 = 0.0;
    var flint: f64 = 0.0;
    var cookson: f64 = 0.0;
    var telescoping = [_]f64{0.0, 0.0};
    var harmonic = [_]f64{0.0, 0.0};
    var zeta = [_]f64{0.0, 0.0};
    var alternating = [_]f64{0.0, 0.0};
    var gregory = [_]f64{0.0, 0.0};
    var term: f64 = 1.0;
    const vector_limit = n + (n & 1);
    for (1..vector_limit + 1) |k| {
        const kd: f64 = @floatFromInt(k);
        const lane = (k - 1) & 1;
        if (k <= n) {
            const k3 = kd * kd * kd;
            const s = @sin(kd);
            const c = @cos(kd);
            geometric += term;
            term *= 2.0 / 3.0;
            inverse_sqrt += 1.0 / @sqrt(kd);
            flint += 1.0 / (k3 * s * s);
            cookson += 1.0 / (k3 * c * c);
        }
        telescoping[lane] += 1.0 / (kd * (kd + 1.0));
        harmonic[lane] += 1.0 / kd;
        zeta[lane] += 1.0 / (kd * kd);
        const sign: f64 = if (lane == 0) 1.0 else -1.0;
        alternating[lane] += sign / kd;
        gregory[lane] += sign / (2.0 * kd - 1.0);
    }
    if (output_opt == null or capacity < OUTPUT_COUNT) return -2;
    const output = output_opt.?;
    output[0] = geometric;
    output[1] = inverse_sqrt;
    output[2] = telescoping[0] + telescoping[1];
    output[3] = flint;
    output[4] = cookson;
    output[5] = harmonic[0] + harmonic[1];
    output[6] = zeta[0] + zeta[1];
    output[7] = alternating[0] + alternating[1];
    output[8] = gregory[0] + gregory[1];
    return OUTPUT_COUNT;
}
