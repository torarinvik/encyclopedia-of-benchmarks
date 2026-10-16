/// Preserve the six integer weight-conversion strings from the pinned Ruby source.
const max_amount: i64 = 1_000_000;

fn appendText(buffer: *[64]u8, position_input: usize, text: []const u8) usize {
    var position = position_input;
    for (text) |byte| {
        buffer[position] = byte;
        position += 1;
    }
    return position;
}

fn appendI64(buffer: *[64]u8, position_input: usize, value: i64) usize {
    var position = position_input;
    var digits: [24]u8 = undefined;
    var count: usize = 0;
    var magnitude = value;
    if (magnitude < 0) {
        buffer[position] = '-';
        position += 1;
        magnitude = -magnitude;
    }
    while (true) {
        digits[count] = '0' + @as(u8, @intCast(@mod(magnitude, 10)));
        count += 1;
        magnitude = @divTrunc(magnitude, 10);
        if (magnitude == 0) break;
    }
    while (count > 0) {
        count -= 1;
        buffer[position] = digits[count];
        position += 1;
    }
    return position;
}

fn appendFixed(buffer: *[64]u8, position_input: usize, value: f64) usize {
    var position = position_input;
    const scaled = value * 100.0;
    var cents: i64 = if (scaled < 0.0)
        -@as(i64, @intFromFloat(-scaled + 0.5))
    else
        @intFromFloat(scaled + 0.5);
    if (value > 0.0 and (@as(f64, @floatFromInt(cents)) + 0.5) / 100.0 <= value) cents += 1
    else if (value < 0.0 and (@as(f64, @floatFromInt(cents)) - 0.5) / 100.0 >= value) cents -= 1;
    if (cents < 0) {
        buffer[position] = '-';
        position += 1;
        cents = -cents;
    }
    position = appendI64(buffer, position, @divTrunc(cents, 100));
    const fraction = @mod(cents, 100);
    buffer[position] = '.';
    position += 1;
    if (fraction == 0) {
        buffer[position] = '0';
        position += 1;
    } else if (@mod(fraction, 10) == 0) {
        buffer[position] = '0' + @as(u8, @intCast(@divTrunc(fraction, 10)));
        position += 1;
    } else {
        buffer[position] = '0' + @as(u8, @intCast(@divTrunc(fraction, 10)));
        buffer[position + 1] = '0' + @as(u8, @intCast(@mod(fraction, 10)));
        position += 2;
    }
    return position;
}

export fn weight_conversions(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length != 2) return -1;
    const operation = input[0];
    const amount = input[1];
    if (operation < 0 or operation > 5 or amount < -max_amount or amount > max_amount) return -1;
    var buffer: [64]u8 = @splat(0);
    var position: usize = 0;
    var converted: i64 = 0;
    if (operation == 0) {
        position = appendI64(&buffer, position, amount);
        position = appendText(&buffer, position, " kg = ");
        position = appendI64(&buffer, position, amount * 1000);
        position = appendText(&buffer, position, " g");
    } else if (operation == 1) {
        converted = if (amount >= 0) @divTrunc(amount, 1000) else -@divTrunc(-amount + 999, 1000);
        position = appendI64(&buffer, position, amount);
        position = appendText(&buffer, position, " g = ");
        position = appendI64(&buffer, position, converted);
        position = appendText(&buffer, position, " kg");
    } else if (operation == 2) {
        position = appendI64(&buffer, position, amount);
        position = appendText(&buffer, position, " lb = ");
        position = appendI64(&buffer, position, amount * 16);
        position = appendText(&buffer, position, " oz");
    } else if (operation == 3) {
        converted = if (amount >= 0) @divTrunc(amount, 16) else -@divTrunc(-amount + 15, 16);
        position = appendI64(&buffer, position, amount);
        position = appendText(&buffer, position, " oz = ");
        position = appendI64(&buffer, position, converted);
        position = appendText(&buffer, position, " lb");
    } else if (operation == 4) {
        position = appendI64(&buffer, position, amount);
        position = appendText(&buffer, position, " kg = ");
        position = appendFixed(&buffer, position, @as(f64, @floatFromInt(amount)) * 2.205);
        position = appendText(&buffer, position, " lb");
    } else {
        position = appendI64(&buffer, position, amount);
        position = appendText(&buffer, position, " lb = ");
        position = appendFixed(&buffer, position, @as(f64, @floatFromInt(amount)) / 2.205);
        position = appendText(&buffer, position, " kg");
    }
    buffer[position] = 0;
    if (output == null or output_capacity < position + 1) return -2;
    for (0..position + 1) |index| output[index] = buffer[index];
    return @intCast(position);
}
