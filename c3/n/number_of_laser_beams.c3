module number_of_laser_beams;

const MAX_DIMENSION = 64;
const MAX_CELLS = 4096;

// Count adjacent nonempty-row device pairs in a fixed-width binary bank.
fn long number_of_laser_beams(long* input, usz length) @export("number_of_laser_beams") {
    if (input == null || length < 2 || length > MAX_CELLS + 2) { return -1; }
    if (input[0] < 1 || input[0] > MAX_DIMENSION || input[1] < 1 || input[1] > MAX_DIMENSION) { return -1; }
    usz rows = (usz)input[0];
    usz columns = (usz)input[1];
    if (length != rows * columns + 2) { return -1; }

    long previous_devices = 0;
    long beams = 0;
    for (usz row = 0; row < rows; row++) {
        long devices = 0;
        for (usz column = 0; column < columns; column++) {
            long cell = input[2 + row * columns + column];
            if (cell != 48 && cell != 49) { return -1; }
            if (cell == 49) { devices++; }
        }
        if (devices != 0) {
            beams += devices * previous_devices;
            previous_devices = devices;
        }
    }
    return beams;
}
