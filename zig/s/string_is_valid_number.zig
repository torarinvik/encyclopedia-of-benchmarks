export fn string_is_valid_number(bytes: [*]const i64, length: usize) i64 {
    if (length > 256) return -1;
    for (0..length) |i| {
        if (bytes[i] < 0 or bytes[i] > 127) return -1;
    }

    var state: i64 = 0;
    for (0..length) |i| {
        const ch = bytes[i];
        if (ch >= 48 and ch <= 57) {
            if (state == 0 or state == 1) {
                state = 2;
            } else if (state == 3) {
                state = 4;
            } else if (state == 5 or state == 6) {
                state = 7;
            } else if (state != 2 and state != 4 and state != 7) {
                return 0;
            }
        } else if (ch == 43 or ch == 45) {
            if (state == 0) {
                state = 1;
            } else if (state == 5) {
                state = 6;
            } else {
                return 0;
            }
        } else if (ch == 46) {
            if (state == 0 or state == 1) {
                state = 3;
            } else if (state == 2) {
                state = 4;
            } else {
                return 0;
            }
        } else if (ch == 101 or ch == 69) {
            if (state == 2 or state == 4) {
                state = 5;
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }
    return if (state == 2 or state == 4 or state == 7) 1 else 0;
}
