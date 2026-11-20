const max_length: usize = 1024;
const buffer_size: usize = 8;

fn sortBuffer(buffer: *[buffer_size]i64, length: usize) void {
    for (1..length) |index| {
        const value = buffer[index];
        var position = index;
        while (position > 0 and value < buffer[position - 1]) {
            buffer[position] = buffer[position - 1];
            position -= 1;
        }
        buffer[position] = value;
    }
}

fn sortRange(values: []i64, first_arg: isize, last_arg: isize) void {
    var first = first_arg;
    var last = last_arg;
    while (last > first) {
        var read_low = first;
        var write_low = first;
        var read_high = last;
        var write_high = last;
        var buffer: [buffer_size]i64 = undefined;
        var buffered: usize = 0;
        var have_max_lower = false;
        var have_min_upper = false;
        var max_lower: i64 = 0;
        var min_upper: i64 = 0;
        var lower_written_bound = first - 1;
        var upper_written_bound = last + 1;

        while (read_high >= read_low) {
            var incoming: i64 = undefined;
            if (read_low - write_low < write_high - read_high) {
                incoming = values[@intCast(read_low)];
                read_low += 1;
            } else {
                incoming = values[@intCast(read_high)];
                read_high -= 1;
            }

            if (buffered < buffer_size) {
                buffer[buffered] = incoming;
                buffered += 1;
                sortBuffer(&buffer, buffered);
            } else if (incoming > buffer[buffer_size - 1]) {
                if (have_min_upper and incoming > min_upper) {
                    upper_written_bound = write_high
                } else {
                    min_upper = incoming;
                    have_min_upper = true;
                }
                values[@intCast(write_high)] = incoming;
                write_high -= 1;
            } else if (incoming < buffer[0]) {
                if (have_max_lower and incoming < max_lower) {
                    lower_written_bound = write_low
                } else {
                    max_lower = incoming;
                    have_max_lower = true;
                }
                values[@intCast(write_low)] = incoming;
                write_low += 1;
            } else if (write_low - first < last - write_high) {
                const outgoing = buffer[0];
                values[@intCast(write_low)] = outgoing;
                write_low += 1;
                max_lower = outgoing;
                have_max_lower = true;
                buffer[0] = incoming;
                sortBuffer(&buffer, buffer_size);
            } else {
                const outgoing = buffer[buffer_size - 1];
                values[@intCast(write_high)] = outgoing;
                write_high -= 1;
                min_upper = outgoing;
                have_min_upper = true;
                buffer[buffer_size - 1] = incoming;
                sortBuffer(&buffer, buffer_size);
            }
        }

        while (buffered > 0) {
            buffered -= 1;
            values[@intCast(write_high)] = buffer[buffered];
            write_high -= 1;
        }

        if (lower_written_bound - first < last - upper_written_bound) {
            sortRange(values, first, lower_written_bound);
            first = upper_written_bound;
        } else {
            sortRange(values, upper_written_bound, last);
            last = lower_written_bound;
        }
    }
}

export fn external_quicksort(values: [*]i64, length: usize) void {
    if (length == 0 or length > max_length) return;
    sortRange(values[0..length], 0, @as(isize, @intCast(length)) - 1);
}
