module strobogrammatic_number;

const MAX_INPUT_LENGTH = 64;

fn long rotated_digit(long value) {
    if (value == '0') return '0';
    if (value == '1') return '1';
    if (value == '6') return '9';
    if (value == '8') return '8';
    if (value == '9') return '6';
    return -1;
}

fn long strobogrammatic_number(long* bytes, usz length) @export("strobogrammatic_number") {
    if (bytes == null && length != 0 || length > MAX_INPUT_LENGTH) return -1;
    for (usz index = 0; index < length; index++) {
        if (bytes[index] < 0 || bytes[index] > 127) return -1;
    }
    usz left = 0;
    usz right = length;
    while (left < right) {
        right--;
        if (rotated_digit(bytes[left]) != bytes[right]) return 0;
        left++;
    }
    return 1;
}
