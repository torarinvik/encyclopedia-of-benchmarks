/// Count adjacent nonempty-row device pairs in a fixed-width binary bank.
const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;

export fn number_of_laser_beams(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_CELLS + 2) return -1;
    if (input[0] < 1 or input[0] > MAX_DIMENSION or
        input[1] < 1 or input[1] > MAX_DIMENSION) return -1;
    const rows: usize = @intCast(input[0]);
    const columns: usize = @intCast(input[1]);
    if (length != rows * columns + 2) return -1;

    var invalid_bits: u64 = 0;
    var previous_devices: u64 = 0;
    var beams: u64 = 0;
    var row_start: usize = 2;
    while (row_start < length) : (row_start += columns) {
        var devices: u64 = 0;
        for (0..columns) |column| {
            const cell: u64 = @bitCast(input[row_start + column]);
            invalid_bits |= cell ^ 48;
            devices += cell & 1;
        }
        beams += devices * previous_devices;
        if (devices != 0) previous_devices = devices;
    }
    if (invalid_bits > 1) return -1;
    return @intCast(beams);
}
