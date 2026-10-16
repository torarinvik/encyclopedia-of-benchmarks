module brightness;

fn long brightness(long* input, usz length) @export("brightness") {
    if (input == null || length != 3) return -1;
    for (usz channel = 0; channel < 3; channel++) {
        if (input[channel] < 0 || input[channel] > 255) return -1;
    }

    long[44] training = {
        2, 99, 255, 1, 37, 44, 58, 0, 139, 169, 229, 1,
        14, 255, 10, 1, 2, 28, 1, 0, 20, 33, 20, 0,
        252, 227, 65, 1, 71, 65, 24, 0, 168, 80, 80, 1,
        119, 35, 90, 0, 186, 13, 126, 1,
    };
    long best_distance = 195076;
    long best_label = -1;
    for (usz sample = 0; sample < 11; sample++) {
        long red_delta = input[0] - training[sample * 4];
        long green_delta = input[1] - training[sample * 4 + 1];
        long blue_delta = input[2] - training[sample * 4 + 2];
        long distance = red_delta * red_delta + green_delta * green_delta + blue_delta * blue_delta;
        if (distance < best_distance) {
            best_distance = distance;
            best_label = training[sample * 4 + 3];
        }
    }
    return best_label;
}
