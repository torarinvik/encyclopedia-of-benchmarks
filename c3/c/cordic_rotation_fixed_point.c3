module cordic_rotation_fixed_point;

const usz OUTPUT_BYTES = 24;
const long ANGLES[15] = {
    785398163, 463647609, 244978663, 124354995, 62418810,
    31239833, 15623729, 7812341, 3906230, 1953123,
    976562, 488281, 244141, 122070, 61035,
};

fn long shift_floor(long value, usz shift) {
    if (shift == 0) return value;
    long divisor = (long)(1 << shift);
    if (value >= 0) return value / divisor;
    return -((-value + divisor - 1) / divisor);
}

fn void put_f64(double value, char* output, usz offset) {
    ulong bits = bitcast(value, ulong);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
    }
}

fn long cordic_rotation_fixed_point(long* values, usz length, char* output, usz capacity)
    @export("cordic_rotation_fixed_point") {
    if (values == null || length < 2 || length > 3) return -1;
    if (length != 2) return -1;
    long angle = values[0], stages = values[1];
    if (angle < -3141592653 || angle > 3141592653 || stages < 1 || stages > 16) return -1;
    if (output == null || capacity < OUTPUT_BYTES) return -2;

    long x = 1000000000, y = 0, z = angle;
    long direction = z >= 0 ? 1 : -1;
    if (direction > 0) {
        long old_x = x;
        x = -y;
        y = old_x;
    } else {
        long old_x = x;
        x = y;
        y = -old_x;
    }
    z -= direction * 1570796327;
    for (usz shift = 0; shift < (usz)(stages - 1); shift++) {
        direction = z >= 0 ? 1 : -1;
        long old_x = x, old_y = y;
        x = old_x - direction * shift_floor(old_y, shift);
        y = old_y + direction * shift_floor(old_x, shift);
        z -= direction * ANGLES[shift];
    }

    char staged[OUTPUT_BYTES];
    put_f64((double)x / 1000000000.0, staged, 0);
    put_f64((double)y / 1000000000.0, staged, 8);
    put_f64((double)z / 1000000000.0, staged, 16);
    for (usz byte = 0; byte < OUTPUT_BYTES; byte++) output[byte] = staged[byte];
    return (long)OUTPUT_BYTES;
}
