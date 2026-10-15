module is_ip_v4_address_valid;

const MAX_INPUT_LENGTH = 32;

fn long is_ip_v4_address_valid(long* bytes, usz length) @export("is_ip_v4_address_valid") {
    if (bytes == null && length != 0 || length > MAX_INPUT_LENGTH) return -1;
    for (usz index = 0; index < length; index++) {
        if (bytes[index] < 0 || bytes[index] > 127) return -1;
    }
    usz segment_count = 0;
    usz digit_count = 0;
    long octet = 0;
    bool leading_zero = false;
    for (usz index = 0; index < length; index++) {
        long value = bytes[index];
        if (value == '.') {
            if (digit_count == 0 || octet > 255 || segment_count >= 3) return 0;
            segment_count++;
            digit_count = 0;
            octet = 0;
            leading_zero = false;
        } else {
            if (value < '0' || value > '9') return 0;
            if (digit_count == 0) leading_zero = value == '0';
            else if (leading_zero) return 0;
            octet = octet * 10 + value - '0';
            if (octet > 255) return 0;
            digit_count++;
            if (digit_count > 3) return 0;
        }
    }
    return segment_count == 3 && digit_count > 0 && octet <= 255 ? 1 : 0;
}
