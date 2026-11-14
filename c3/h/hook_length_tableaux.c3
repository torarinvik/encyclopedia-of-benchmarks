// Independent hook-length count; see package README.
module hook_length_tableaux;
const long PRIME = 998244353;

fn long hook_length_tableaux(long* input, usz length) @export("hook_length_tableaux") {
    if (input == null || length == 0 || input[0] < 0 || input[0] > 65536) return -1;
    usz rows = (usz)input[0];
    if (length != rows + 1) return -1;
    long total = 0, previous = 1000000;
    for (usz i = 1; i <= rows; i++) {
        long width = input[i];
        if (width < 1 || width > previous) return -1;
        total += width; if (total > 1000000) return -1;
        previous = width;
    }
    long hooks = 1;
    usz height = rows;
    if (rows > 0) {
        for (long col = 0; col < input[1]; col++) {
            while (height > 0 && input[height] <= col) height--;
            for (usz row = 0; row < height; row++)
                hooks = hooks * (input[row + 1] - col + (long)(height - row - 1)) % PRIME;
        }
    }
    long factorial = 1;
    for (long i = 2; i <= total; i++) factorial = factorial * i % PRIME;
    long inverse = 1, exponent = PRIME - 2;
    while (exponent > 0) {
        if ((exponent & 1) != 0) inverse = inverse * hooks % PRIME;
        hooks = hooks * hooks % PRIME; exponent >>= 1;
    }
    return factorial * inverse % PRIME;
}
