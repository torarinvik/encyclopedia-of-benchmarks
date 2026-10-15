/// Format a bounded multiplication table as source-faithful ASCII lines.
fn decimalLength(value: i64) usize {
    var magnitude = if (value < 0) -value else value;
    var length: usize = 1;
    if (value < 0) length += 1;
    while (magnitude >= 10) : (magnitude = @divTrunc(magnitude, 10)) length += 1;
    return length;
}

fn appendDecimal(output: [*]u8, position: *usize, value: i64) void {
    var magnitude = if (value < 0) -value else value;
    if (value < 0) {
        output[position.*] = '-';
        position.* += 1;
    }
    var reversed: [20]u8 = undefined;
    var count: usize = 0;
    while (true) {
        reversed[count] = '0' + @as(u8, @intCast(@mod(magnitude, 10)));
        count += 1;
        magnitude = @divTrunc(magnitude, 10);
        if (magnitude == 0) break;
    }
    while (count > 0) {
        count -= 1;
        output[position.*] = reversed[count];
        position.* += 1;
    }
}

export fn print_multiplication_table(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length != 2) return -1;
    const number = input[0];
    const terms = input[1];
    if (number < -1000000 or number > 1000000 or terms < -20 or terms > 20) return -1;
    var required: usize = 0;
    if (terms > 0) required = @intCast(terms - 1);
    var multiplier: i64 = 1;
    while (multiplier <= terms) : (multiplier += 1) {
        const product = number * multiplier;
        required += decimalLength(number) + 3 + decimalLength(multiplier) + 3 + decimalLength(product);
    }
    if (output_capacity < required) return -2;
    var position: usize = 0;
    multiplier = 1;
    while (multiplier <= terms) : (multiplier += 1) {
        if (multiplier > 1) {
            output[position] = '\n';
            position += 1;
        }
        appendDecimal(output, &position, number);
        output[position] = ' ';
        output[position + 1] = '*';
        output[position + 2] = ' ';
        position += 3;
        appendDecimal(output, &position, multiplier);
        output[position] = ' ';
        output[position + 1] = '=';
        output[position + 2] = ' ';
        position += 3;
        appendDecimal(output, &position, number * multiplier);
    }
    return @intCast(position);
}
