const MAX_COUNT: i64 = 1000;
const MAX_STATE: i64 = 139967;
const WIDTH: usize = 60;
const ALU = "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG" ++
    "GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA" ++
    "CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT" ++
    "ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA" ++
    "GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG" ++
    "AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC" ++
    "AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA";
const IUB_WEIGHTS = [_]f32{0.27,0.12,0.12,0.27,0.02,0.02,0.02,0.02,0.02,0.02,0.02,0.02,0.02,0.02,0.02};
const IUB_SYMBOLS = [_]u8{'a','c','g','t','B','D','H','K','M','N','R','S','V','W','Y'};
const HUMAN_WEIGHTS = [_]f32{0.3029549426680,0.1979883004921,0.1975473066391,0.3015094502008};
const HUMAN_SYMBOLS = [_]u8{'a','c','g','t'};

fn wrappedLines(count: usize) usize { return (count + WIDTH - 1) / WIDTH; }

fn fastaOutputLength(count: usize) usize {
    return 77 + 10 * count + wrappedLines(2 * count) + wrappedLines(3 * count) + wrappedLines(5 * count);
}

fn accumulateProbabilities(weights: []f32) void {
    var cumulative: f32 = 0.0;
    for (weights) |*weight| {
        cumulative += weight.*;
        weight.* = cumulative;
    }
}

fn nextWeightedBase(state: *u32, weights: []const f32, symbols: []const u8) u8 {
    state.* = (state.* * 3877 + 29573) % 139968;
    const random_value: f32 = 1.0 * @as(f32, @floatFromInt(state.*)) / 139968.0;
    for (weights, 0..) |weight, index| {
        if (weight >= random_value) return symbols[index];
    }
    return symbols[symbols.len - 1];
}

fn writeRepeat(output: [*c]u8, offset: usize, count: usize) usize {
    var position = offset;
    for (0..count) |index| {
        output[position] = ALU[index % ALU.len]; position += 1;
        if ((index + 1) % WIDTH == 0 or index + 1 == count) {
            output[position] = 10; position += 1;
        }
    }
    return position;
}

fn writeWeighted(output: [*c]u8, offset: usize, count: usize, state: *u32,
                 weights: []const f32, symbols: []const u8) usize {
    var position = offset;
    for (0..count) |index| {
        output[position] = nextWeightedBase(state, weights, symbols); position += 1;
        if ((index + 1) % WIDTH == 0 or index + 1 == count) {
            output[position] = 10; position += 1;
        }
    }
    return position;
}

export fn beebs_fasta(values: [*c]const i64, length: usize,
                      output: [*c]u8, capacity: usize) i64 {
    if (values == null or length != 2) return -1;
    const count_value = values[0];
    const seed_value = values[1];
    if (count_value < 1 or count_value > MAX_COUNT or seed_value < 0 or seed_value > MAX_STATE) return -1;
    const count: usize = @intCast(count_value);
    const needed = fastaOutputLength(count);
    if (output == null or capacity < needed) return -2;
    var iub_weights = IUB_WEIGHTS;
    var human_weights = HUMAN_WEIGHTS;
    accumulateProbabilities(iub_weights[0..]);
    accumulateProbabilities(human_weights[0..]);
    const header_one = ">ONE Homo sapiens alu\n";
    const header_two = ">TWO IUB ambiguity codes\n";
    const header_three = ">THREE Homo sapiens frequency\n";
    var offset: usize = 0;
    for (header_one, 0..) |byte, index| { output[offset + index] = byte; }
    offset += header_one.len;
    offset = writeRepeat(output, offset, 2 * count);
    for (header_two, 0..) |byte, index| { output[offset + index] = byte; }
    offset += header_two.len;
    var state: u32 = @intCast(seed_value);
    offset = writeWeighted(output, offset, 3 * count, &state, iub_weights[0..], &IUB_SYMBOLS);
    for (header_three, 0..) |byte, index| { output[offset + index] = byte; }
    offset += header_three.len;
    offset = writeWeighted(output, offset, 5 * count, &state, human_weights[0..], &HUMAN_SYMBOLS);
    return @intCast(offset);
}
