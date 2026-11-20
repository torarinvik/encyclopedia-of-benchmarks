const MAX_ITEMS: usize = 256;
const RUN_SIZE: usize = 8;
const MAX_RUNS: usize = 34;
const Tapes = [3][MAX_ITEMS]i64;
const RunTable = [3][MAX_RUNS]u32;
const TapeCounts = [3]u32;

fn placeRun(input: [*c]const i64, input_length: usize, run_index: u32, tape: usize,
            tapes: *Tapes, starts: *RunTable, lengths: *RunTable,
            counts: *TapeCounts, write_offsets: *TapeCounts) void {
    const slot: usize = counts[0][tape];
    counts[0][tape] += 1;
    const start: usize = write_offsets[0][tape];
    const source = @as(usize, run_index) * RUN_SIZE;
    const run_length = @min(input_length - source, RUN_SIZE);
    for (0..run_length) |i| tapes[0][tape][start + i] = input[source + i];
    for (1..run_length) |i| {
        const value = tapes[0][tape][start + i];
        var position = i;
        while (position > 0 and tapes[0][tape][start + position - 1] > value) {
            tapes[0][tape][start + position] = tapes[0][tape][start + position - 1];
            position -= 1;
        }
        tapes[0][tape][start + position] = value;
    }
    starts[0][tape][slot] = @intCast(start);
    lengths[0][tape][slot] = @intCast(run_length);
    write_offsets[0][tape] += @intCast(run_length);
}

fn placeDummy(tape: usize, starts: *RunTable, lengths: *RunTable,
              counts: *TapeCounts, write_offsets: *const TapeCounts) void {
    const slot: usize = counts[0][tape];
    counts[0][tape] += 1;
    starts[0][tape][slot] = write_offsets[0][tape];
    lengths[0][tape][slot] = 0;
}

fn mergeRun(tapes: *Tapes, starts: *RunTable, lengths: *RunTable,
            counts: *TapeCounts, read_indices: *TapeCounts, write_offsets: *TapeCounts,
            left_tape: usize, right_tape: usize, output_tape: usize) void {
    const left_slot: usize = read_indices[0][left_tape];
    const right_slot: usize = read_indices[0][right_tape];
    read_indices[0][left_tape] += 1;
    read_indices[0][right_tape] += 1;
    const left_start: usize = starts[0][left_tape][left_slot];
    const right_start: usize = starts[0][right_tape][right_slot];
    const left_length: usize = lengths[0][left_tape][left_slot];
    const right_length: usize = lengths[0][right_tape][right_slot];
    const output_slot: usize = counts[0][output_tape];
    counts[0][output_tape] += 1;
    const output_start: usize = write_offsets[0][output_tape];
    var left: usize = 0;
    var right: usize = 0;
    var written: usize = 0;
    while (left < left_length and right < right_length) {
        if (tapes[0][left_tape][left_start + left] <= tapes[0][right_tape][right_start + right]) {
            const value = tapes[0][left_tape][left_start + left];
            tapes[0][output_tape][output_start + written] = value;
            left += 1;
        } else {
            const value = tapes[0][right_tape][right_start + right];
            tapes[0][output_tape][output_start + written] = value;
            right += 1;
        }
        written += 1;
    }
    while (left < left_length) {
        const value = tapes[0][left_tape][left_start + left];
        tapes[0][output_tape][output_start + written] = value;
        left += 1;
        written += 1;
    }
    while (right < right_length) {
        const value = tapes[0][right_tape][right_start + right];
        tapes[0][output_tape][output_start + written] = value;
        right += 1;
        written += 1;
    }
    starts[0][output_tape][output_slot] = @intCast(output_start);
    lengths[0][output_tape][output_slot] = @intCast(written);
    write_offsets[0][output_tape] += @intCast(written);
}

pub export fn polyphase_merge_sort(values: [*c]i64, length: usize) void {
    if (values == null or length < 2 or length > MAX_ITEMS) return;
    var tapes: Tapes = undefined;
    var starts: RunTable = undefined;
    var run_lengths: RunTable = undefined;
    var counts: TapeCounts = @splat(0);
    var read_indices: TapeCounts = @splat(0);
    var write_offsets: TapeCounts = @splat(0);
    const initial_runs: u32 = @intCast((length + RUN_SIZE - 1) / RUN_SIZE);
    var quota_a: u32 = 1;
    var quota_b: u32 = 0;
    while (quota_a + quota_b < initial_runs) {
        const next = quota_a + quota_b;
        quota_b = quota_a;
        quota_a = next;
    }
    var run: u32 = 0;
    for (0..quota_a) |_| {
        if (run < initial_runs) placeRun(values, length, run, 0, &tapes, &starts, &run_lengths, &counts, &write_offsets)
        else placeDummy(0, &starts, &run_lengths, &counts, &write_offsets);
        run += 1;
    }
    for (0..quota_b) |_| {
        if (run < initial_runs) placeRun(values, length, run, 1, &tapes, &starts, &run_lengths, &counts, &write_offsets)
        else placeDummy(1, &starts, &run_lengths, &counts, &write_offsets);
        run += 1;
    }

    var roles: [3]u32 = .{ 0, 1, 2 };
    var remaining_total = counts[0] + counts[1];
    while (remaining_total > 1) {
        const input_a: usize = roles[0];
        const input_b: usize = roles[1];
        const output: usize = roles[2];
        const available_a = counts[input_a] - read_indices[input_a];
        const available_b = counts[input_b] - read_indices[input_b];
        if (available_a == 0 or available_b == 0) break;
        counts[output] = 0;
        read_indices[output] = 0;
        write_offsets[output] = 0;
        const pairs = @min(available_a, available_b);
        for (0..pairs) |_| mergeRun(&tapes, &starts, &run_lengths, &counts,
                                     &read_indices, &write_offsets, input_a, input_b, output);
        const left_a = counts[input_a] - read_indices[input_a];
        const left_b = counts[input_b] - read_indices[input_b];
        remaining_total = left_a + left_b + counts[output];
        if (remaining_total <= 1 or (left_a == 0 and left_b == 0)) break;
        if (left_a > 0) {
            roles[1] = @intCast(output);
            roles[2] = @intCast(input_b);
        } else {
            roles[0] = @intCast(output);
            roles[2] = @intCast(input_a);
        }
    }
    for (0..3) |tape| {
        if (read_indices[tape] < counts[tape]) {
            const slot: usize = read_indices[tape];
            if (run_lengths[tape][slot] == length) {
                const start: usize = starts[tape][slot];
                for (0..length) |i| values[i] = tapes[tape][start + i];
                return;
            }
        }
    }
}
