const max_parseable_input_length: usize = 38;

export fn ipconverter(input: [*c]const i64, length: usize,
                      output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > max_parseable_input_length) return -1;
    const values = input[0..length];
    const mode = values[0];
    const payload_length_value = values[1];
    if ((mode != 0 and mode != 1) or payload_length_value < 0 or payload_length_value > 35) return -1;
    const payload_length: usize = @intCast(payload_length_value);
    if (length != payload_length + 2) return -1;

    var octets: [4]i64 = undefined;
    var position: usize = 0;
    if (mode == 0) {
        if (payload_length < 7 or payload_length > 15) return -1;
        for (0..4) |octet| {
            var digits: usize = 0;
            var value: i64 = 0;
            while (position < payload_length and values[2 + position] != 46) {
                const byte = values[2 + position];
                if (digits == 3 or byte < 48 or byte > 57) return -1;
                value = value * 10 + byte - 48;
                if (value > 255) return -1;
                digits += 1;
                position += 1;
            }
            if (digits == 0) return -1;
            octets[octet] = value;
            if (octet < 3) {
                if (position >= payload_length or values[2 + position] != 46) return -1;
                position += 1;
            } else if (position != payload_length) return -1;
        }
    } else {
        if (payload_length != 35) return -1;
        for (0..4) |octet| {
            var value: i64 = 0;
            for (0..8) |_| {
                const byte = values[2 + position];
                position += 1;
                if (byte != 48 and byte != 49) return -1;
                value = value * 2 + byte - 48;
            }
            octets[octet] = value;
            if (octet < 3) {
                if (values[2 + position] != 46) return -1;
                position += 1;
            }
        }
        if (position != payload_length) return -1;
    }

    var output_length: usize = if (mode == 0) 35 else 3;
    if (mode == 1) {
        for (octets) |value| {
            output_length += if (value >= 100) 2 else if (value >= 10) 1 else 0;
        }
    }
    if (capacity < output_length or output == null) return -2;

    position = 0;
    for (0..4) |octet| {
        if (mode == 0) {
            for (0..8) |bit| {
                const shift: u6 = @intCast(7 - bit);
                output[position] = @intCast(48 + ((octets[octet] >> shift) & 1));
                position += 1;
            }
        } else {
            var value = octets[octet];
            if (value >= 100) { output[position] = @intCast(48 + @divTrunc(value, 100)); position += 1; value = @rem(value, 100); }
            if (value >= 10) { output[position] = @intCast(48 + @divTrunc(value, 10)); position += 1; value = @rem(value, 10); }
            output[position] = @intCast(48 + value);
            position += 1;
        }
        if (octet < 3) { output[position] = 46; position += 1; }
    }
    return @intCast(position);
}
