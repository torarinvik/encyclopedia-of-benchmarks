const training = [_][4]i64{
    .{ 2, 99, 255, 1 }, .{ 37, 44, 58, 0 }, .{ 139, 169, 229, 1 },
    .{ 14, 255, 10, 1 }, .{ 2, 28, 1, 0 }, .{ 20, 33, 20, 0 },
    .{ 252, 227, 65, 1 }, .{ 71, 65, 24, 0 }, .{ 168, 80, 80, 1 },
    .{ 119, 35, 90, 0 }, .{ 186, 13, 126, 1 },
};

export fn brightness(input: [*]const i64, length: usize) i64 {
    if (length != 3) return -1;
    for (0..3) |channel| {
        if (input[channel] < 0 or input[channel] > 255) return -1;
    }

    var best_distance: i64 = 195076;
    var best_label: i64 = -1;
    for (training) |sample| {
        const red_delta = input[0] - sample[0];
        const green_delta = input[1] - sample[1];
        const blue_delta = input[2] - sample[2];
        const distance = red_delta * red_delta + green_delta * green_delta + blue_delta * blue_delta;
        if (distance < best_distance) {
            best_distance = distance;
            best_label = sample[3];
        }
    }
    return best_label;
}
