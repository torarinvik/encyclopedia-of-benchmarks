const MAX_INPUT_LENGTH: usize = 256;

fn isHexDigit(value: i64) bool {
    return (value >= 48 and value <= 57) or (value >= 97 and value <= 102) or (value >= 65 and value <= 70);
}

fn validIpv6Text(input: [*]const i64, text_length: usize) bool {
    if (text_length == 0) return false;
    var groups: usize = 0;
    var group_length: usize = 0;
    var compression_count: usize = 0;
    var in_group = false;
    var index: usize = 0;
    while (index < text_length) {
        const value = input[index + 1];
        if (value == 58) {
            if (index + 1 < text_length and input[index + 2] == 58) {
                if ((index > 0 and input[index] == 58) or
                    (index + 2 < text_length and input[index + 3] == 58) or compression_count != 0) return false;
                if (in_group) {
                    groups += 1;
                    in_group = false;
                    group_length = 0;
                } else if (index != 0) {
                    return false;
                }
                compression_count += 1;
                index += 2;
                continue;
            }
            if (index == 0 or index + 1 == text_length or !in_group) return false;
            groups += 1;
            in_group = false;
            group_length = 0;
            index += 1;
            continue;
        }
        if (!isHexDigit(value) or group_length == 4) return false;
        group_length += 1;
        in_group = true;
        index += 1;
    }
    if (in_group) groups += 1;
    return if (compression_count == 0) groups == 8 else groups < 8;
}

export fn is_ipv6_address_valid(raw: [*]const i64, length: usize) i64 {
    if (length < 1) return -1;
    const declared = raw[0];
    if (declared < 0 or declared > MAX_INPUT_LENGTH) return -1;
    const text_length: usize = @intCast(declared);
    if (length != text_length + 1) return -1;
    for (raw[1 .. text_length + 1]) |value| {
        if (value < 0 or value > 127) return -1;
    }
    return if (validIpv6Text(raw, text_length)) 1 else 0;
}
