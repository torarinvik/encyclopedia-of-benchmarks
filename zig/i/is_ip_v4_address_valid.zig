const MAX_INPUT_LENGTH: usize = 32;

export fn is_ip_v4_address_valid(bytes: [*c]const i64, length: usize) i64 {
    if ((bytes == null and length != 0) or length > MAX_INPUT_LENGTH) return -1;
    if (length == 0) return 0;
    var index: usize = 0;
    while (index < length) : (index += 1) {
        if (bytes[index] < 0 or bytes[index] > 127) return -1;
    }
    var segment_count: usize = 0;
    var digit_count: usize = 0;
    var octet: i64 = 0;
    var leading_zero = false;
    index = 0;
    while (index < length) : (index += 1) {
        const value = bytes[index];
        if (value == 46) {
            if (digit_count == 0 or octet > 255 or segment_count >= 3) return 0;
            segment_count += 1;
            digit_count = 0;
            octet = 0;
            leading_zero = false;
        } else {
            if (value < 48 or value > 57) return 0;
            if (digit_count == 0) leading_zero = value == 48 else if (leading_zero) return 0;
            octet = octet * 10 + value - 48;
            if (octet > 255) return 0;
            digit_count += 1;
            if (digit_count > 3) return 0;
        }
    }
    return if (segment_count == 3 and digit_count > 0 and octet <= 255) 1 else 0;
}
