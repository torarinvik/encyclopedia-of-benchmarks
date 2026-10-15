module is_ipv6_address_valid;

const usz MAX_INPUT_LENGTH = 256;

fn bool is_hex_digit(long value) {
    return (value >= '0' && value <= '9') || (value >= 'a' && value <= 'f') || (value >= 'A' && value <= 'F');
}

fn bool valid_ipv6_text(long* input, usz start, usz length) {
    if (length == 0) return false;
    usz groups = 0;
    usz group_length = 0;
    usz compression_count = 0;
    bool in_group = false;
    usz index = 0;
    while (index < length) {
        long value = input[start + index];
        if (value == ':') {
            if (index + 1 < length && input[start + index + 1] == ':') {
                if ((index > 0 && input[start + index - 1] == ':') ||
                    (index + 2 < length && input[start + index + 2] == ':') || compression_count != 0) return false;
                if (in_group) {
                    groups++;
                    in_group = false;
                    group_length = 0;
                } else if (index != 0) {
                    return false;
                }
                compression_count++;
                index += 2;
                continue;
            }
            if (index == 0 || index + 1 == length || !in_group) return false;
            groups++;
            in_group = false;
            group_length = 0;
            index++;
            continue;
        }
        if (!is_hex_digit(value) || group_length == 4) return false;
        group_length++;
        in_group = true;
        index++;
    }
    if (in_group) groups++;
    return compression_count == 0 ? groups == 8 : groups < 8;
}

fn long is_ipv6_address_valid(long* input, usz length) @export("is_ipv6_address_valid") {
    if (input == null || length < 1 || input[0] < 0 || input[0] > (long)MAX_INPUT_LENGTH) return -1;
    usz text_length = (usz)input[0];
    if (length != text_length + 1) return -1;
    for (usz index = 0; index < text_length; index++) {
        if (input[index + 1] < 0 || input[index + 1] > 127) return -1;
    }
    return valid_ipv6_text(input, 1, text_length) ? 1 : 0;
}
