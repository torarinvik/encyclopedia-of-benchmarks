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

    var previous_devices: i64 = 0;
    var beams: i64 = 0;
    for (0..rows) |row| {
        var devices: i64 = 0;
        for (0..columns) |column| {
            const cell = input[2 + row * columns + column];
            if (cell != 48 and cell != 49) return -1;
            if (cell == 49) devices += 1;
        }
        if (devices != 0) {
            beams += devices * previous_devices;
            previous_devices = devices;
        }
    }
    return beams;
}
