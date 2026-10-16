const SMALL = [_][]const u8{
    "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
    "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
    "Seventeen", "Eighteen", "Nineteen", "Twenty",
};
const TENS = [_][]const u8{"", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"};
const SCALES = [_][]const u8{"", "Thousand", "Million", "Billion"};

fn appendText(buffer: *[128]u8, position_input: usize, text: []const u8) usize {
    var position = position_input;
    for (text) |byte| {
        buffer[position] = byte;
        position += 1;
    }
    return position;
}

fn appendWord(buffer: *[128]u8, position_input: usize, text: []const u8) usize {
    var position = position_input;
    if (position != 0) {
        buffer[position] = ' ';
        position += 1;
    }
    return appendText(buffer, position, text);
}

fn appendGroup(buffer: *[128]u8, position_input: usize, value_input: usize) usize {
    var position = position_input;
    var value = value_input;
    if (value >= 100) {
        position = appendWord(buffer, position, SMALL[value / 100]);
        position = appendWord(buffer, position, "Hundred");
        value %= 100;
    }
    if (value <= 20) {
        if (value != 0) position = appendWord(buffer, position, SMALL[value]);
    } else if (value % 10 == 0) {
        position = appendWord(buffer, position, TENS[value / 10]);
    } else {
        position = appendWord(buffer, position, TENS[value / 10]);
        position = appendWord(buffer, position, SMALL[value % 10]);
    }
    return position;
}

export fn integer_to_english(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length != 1) return -1;
    const value = input.?[0];
    if (value < -2147483648 or value > 2147483647) return -1;
    var buffer: [128]u8 = undefined;
    var position: usize = 0;
    if (value == 0) {
        position = appendWord(&buffer, position, "Zero");
    } else if (value > 0) {
        var groups: [4]usize = [_]usize{0} ** 4;
        var remaining: usize = @intCast(value);
        var count: usize = 0;
        while (remaining != 0) {
            groups[count] = remaining % 1000;
            count += 1;
            remaining /= 1000;
        }
        while (count > 0) {
            count -= 1;
            if (groups[count] != 0) {
                position = appendGroup(&buffer, position, groups[count]);
                if (count != 0) position = appendWord(&buffer, position, SCALES[count]);
            }
        }
    }
    if (position > output_capacity or (position != 0 and output == null)) return -2;
    for (0..position) |index| output.?[index] = buffer[index];
    return @intCast(position);
}
