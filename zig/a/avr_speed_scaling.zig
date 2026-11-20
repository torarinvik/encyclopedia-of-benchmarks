const MAX_JOBS: usize = 8;
const MAX_TIME: usize = 8;
const MAX_SEGMENTS: usize = 15;
const MAX_INPUT_LENGTH: usize = 25;
const MAX_OUTPUT_VALUES: usize = 79;
const DENSITY_SCALE: i64 = 840;

fn gcdI64(left: i64, right: i64) i64 {
    var a = left;
    var b = right;
    while (b != 0) {
        const remainder = @rem(a, b);
        a = b;
        b = remainder;
    }
    return a;
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn avr_speed_scaling(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const count_value = values[0];
    if (count_value < 1 or count_value > @as(i64, @intCast(MAX_JOBS))) return -1;
    const count: usize = @intCast(count_value);
    if (length != 1 + 3 * count) return -1;

    var releases: [MAX_JOBS]usize = @splat(0);
    var deadlines: [MAX_JOBS]usize = @splat(0);
    var remaining: [MAX_JOBS]i64 = @splat(0);
    var finish_numerators: [MAX_JOBS]i64 = @splat(0);
    var finish_denominators: [MAX_JOBS]i64 = @splat(0);
    var changes: [MAX_TIME + 1]i64 = @splat(0);
    var endpoint: [MAX_TIME + 1]bool = @splat(false);
    for (0..count) |job| {
        const offset = 1 + 3 * job;
        const release_value = values[offset];
        const deadline_value = values[offset + 1];
        const work_value = values[offset + 2];
        if (release_value < 0 or release_value >= deadline_value or
            deadline_value > @as(i64, @intCast(MAX_TIME)) or
            work_value < 1 or work_value > 8) return -1;
        const release: usize = @intCast(release_value);
        const deadline: usize = @intCast(deadline_value);
        releases[job] = release;
        deadlines[job] = deadline;
        remaining[job] = work_value * DENSITY_SCALE;
        const window_length: i64 = @intCast(deadline - release);
        const scaled_density = work_value * (DENSITY_SCALE / window_length);
        changes[release] += scaled_density;
        changes[deadline] -= scaled_density;
        endpoint[release] = true;
        endpoint[deadline] = true;
    }

    var speed_scaled: i64 = 0;
    var energy_scaled: i64 = 0;
    var segments: [MAX_SEGMENTS][4]i64 = undefined;
    var segment_count: usize = 0;
    for (0..MAX_TIME) |start| {
        speed_scaled += changes[start];
        if (!endpoint[start]) continue;
        var finish = start + 1;
        while (finish <= MAX_TIME and !endpoint[finish]) : (finish += 1) {}
        if (finish > MAX_TIME or speed_scaled <= 0) continue;

        const duration: i64 = @intCast(finish - start);
        energy_scaled += speed_scaled * speed_scaled * speed_scaled * duration;
        const speed_divisor = gcdI64(speed_scaled, DENSITY_SCALE);
        const speed_numerator = speed_scaled / speed_divisor;
        const speed_denominator = DENSITY_SCALE / speed_divisor;
        if (segment_count > 0 and segments[segment_count - 1][1] == @as(i64, @intCast(start)) and
            segments[segment_count - 1][2] == speed_numerator and
            segments[segment_count - 1][3] == speed_denominator)
        {
            segments[segment_count - 1][1] = @intCast(finish);
        } else {
            segments[segment_count] = .{
                @intCast(start), @intCast(finish), speed_numerator, speed_denominator,
            };
            segment_count += 1;
        }

        var cursor_scaled: i64 = @intCast(start);
        cursor_scaled *= speed_scaled;
        const end_scaled: i64 = @as(i64, @intCast(finish)) * speed_scaled;
        while (cursor_scaled < end_scaled) {
            var selected: i32 = -1;
            for (0..count) |job| {
                if (releases[job] <= start and start < deadlines[job] and remaining[job] > 0 and
                    (selected < 0 or deadlines[job] < deadlines[@intCast(selected)]))
                {
                    selected = @intCast(job);
                }
            }
            if (selected < 0) break;
            const job: usize = @intCast(selected);
            const needed_scaled = remaining[job];
            if (cursor_scaled + needed_scaled <= end_scaled) {
                cursor_scaled += needed_scaled;
                remaining[job] = 0;
                const divisor = gcdI64(cursor_scaled, speed_scaled);
                finish_numerators[job] = cursor_scaled / divisor;
                finish_denominators[job] = speed_scaled / divisor;
            } else {
                remaining[job] -= end_scaled - cursor_scaled;
                cursor_scaled = end_scaled;
            }
        }
    }

    const energy_denominator = DENSITY_SCALE * DENSITY_SCALE * DENSITY_SCALE;
    const energy_divisor = gcdI64(energy_scaled, energy_denominator);
    var fields: [MAX_OUTPUT_VALUES]i64 = undefined;
    var field_count: usize = 0;
    fields[field_count] = @intCast(segment_count);
    field_count += 1;
    fields[field_count] = energy_scaled / energy_divisor;
    field_count += 1;
    fields[field_count] = energy_denominator / energy_divisor;
    field_count += 1;
    for (0..segment_count) |segment| {
        for (0..4) |part| {
            fields[field_count] = segments[segment][part];
            field_count += 1;
        }
    }
    for (0..count) |job| {
        if (finish_denominators[job] <= 0) return -1;
        fields[field_count] = finish_numerators[job];
        field_count += 1;
        fields[field_count] = finish_denominators[job];
        field_count += 1;
    }

    const output_bytes = field_count * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    for (0..field_count) |field| storeI64Le(output, field * 8, fields[field]);
    return @intCast(output_bytes);
}
