const SOURCE_CALLS: i64 = 1;
const OUTPUT_BYTES: usize = 13;
const SOURCE_OUTPUT = "hello world\n\n";

export fn shootout_hello(calls: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (calls != SOURCE_CALLS) return -1;
    if (output_opt == null or output_capacity < OUTPUT_BYTES) return -2;
    var staged: [OUTPUT_BYTES]u8 = undefined;
    for (0..OUTPUT_BYTES) |index| staged[index] = SOURCE_OUTPUT[index];
    const output = output_opt.?;
    for (0..OUTPUT_BYTES) |index| output[index] = staged[index];
    return OUTPUT_BYTES;
}
