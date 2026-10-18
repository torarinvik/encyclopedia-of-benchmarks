const INVALID_RESULT: i64 = -1;
const OUTPUT_ERROR: i64 = -2;
const INPUT_LENGTH: usize = 6;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 7;

fn inRange(value: f64, minimum: f64, maximum: f64) bool {
    return value >= minimum and value <= maximum;
}

export fn sir(input: ?[*]const f64, input_length: usize, output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return INVALID_RESULT;
    if (input_length < INPUT_LENGTH or input_length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    if (input_length != INPUT_LENGTH) return INVALID_RESULT;

    const s = values[0];
    const i = values[1];
    const r = values[2];
    const beta = values[3];
    const k = values[4];
    const time = values[5];
    if (!inRange(s, 0.0, 1_000_000.0) or !inRange(i, 0.0, 1_000_000.0) or
        !inRange(r, 0.0, 1_000_000.0) or !inRange(beta, 0.0, 0.001) or
        !inRange(k, 0.0, 1.0) or !inRange(time, 0.0, 140.0)) return INVALID_RESULT;

    const d_s = ((-beta) * s) * i;
    const d_i_infection = (beta * s) * i;
    const d_i_recovery = k * i;
    const d_i = d_i_infection - d_i_recovery;
    const d_r = k * i;

    const out = output orelse return OUTPUT_ERROR;
    if (output_capacity < 3) return OUTPUT_ERROR;
    out[0] = d_s;
    out[1] = d_i;
    out[2] = d_r;
    return 3;
}
