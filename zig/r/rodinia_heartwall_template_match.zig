// Clean-room bounded Heartwall score/selection; see package LICENSE.txt.
const std = @import("std");

fn addf(a: f32, b: f32) f32 { return a + b; }
fn subf(a: f32, b: f32) f32 { return a - b; }
fn mulf(a: f32, b: f32) f32 { return a * b; }
fn divf(a: f32, b: f32) f32 { return a / b; }

fn put64(output: []u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |index| output[index] = @truncate(bits >> @intCast(8 * index));
}

pub export fn rodinia_heartwall_template_match(input_ptr: ?[*]const i64, length: usize,
    output_ptr: ?[*]u8, capacity: usize) i64
{
    const input = input_ptr orelse return -1;
    if (length < 5 or length > 85) return -1;
    const ir_raw = input[0];
    const ic_raw = input[1];
    const tr_raw = input[2];
    const tc_raw = input[3];
    const mask_raw = input[4];
    if (ir_raw < 2 or ir_raw > 8 or ic_raw < 2 or ic_raw > 8 or
        tr_raw < 2 or tr_raw > 4 or tc_raw < 2 or tc_raw > 4 or
        tr_raw > ir_raw or tc_raw > ic_raw or mask_raw < 0) return -1;

    const ir: usize = @intCast(ir_raw);
    const ic: usize = @intCast(ic_raw);
    const tr: usize = @intCast(tr_raw);
    const tc: usize = @intCast(tc_raw);
    const row_candidates = ir - tr + 1;
    const col_candidates = ic - tc + 1;
    const candidate_count = row_candidates * col_candidates;
    const mask: u64 = @intCast(mask_raw);
    if ((mask >> @intCast(candidate_count)) != 0 or length != 5 + tr * tc + ir * ic) return -1;
    for (5..length) |index| if (input[index] < 0 or input[index] > 255) return -1;

    const template_count = tr * tc;
    const image_base = 5 + template_count;
    var template_sum: f32 = 0;
    var template_square_sum: f32 = 0;
    for (0..tc) |column| {
        for (0..tr) |row| {
            const value: f32 = @floatFromInt(input[5 + column * tr + row]);
            template_sum = addf(template_sum, value);
            template_square_sum = addf(template_square_sum, mulf(value, value));
        }
    }
    const count_f: f32 = @floatFromInt(template_count);
    const template_mean = divf(template_sum, count_f);
    const template_variance = subf(divf(template_square_sum, count_f), mulf(template_mean, template_mean));
    if (!(template_variance > 0)) return -1;
    const template_denominator = mulf(@sqrt(@as(f32, @floatFromInt(template_count - 1))), @sqrt(template_variance));

    var best_magnitude: f32 = 0;
    var best_index: usize = 0;
    var candidate_index: usize = 0;
    for (0..col_candidates) |column_start| {
        for (0..row_candidates) |row_start| {
            if (((mask >> @intCast(candidate_index)) & 1) != 0) {
                var patch_sum: f32 = 0;
                var patch_square_sum: f32 = 0;
                var dot: f32 = 0;
                for (0..tc) |column| {
                    for (0..tr) |row| {
                        const t: f32 = @floatFromInt(input[5 + column * tr + row]);
                        const p: f32 = @floatFromInt(input[image_base + (column_start + column) * ir + row_start + row]);
                        patch_sum = addf(patch_sum, p);
                        patch_square_sum = addf(patch_square_sum, mulf(p, p));
                        dot = addf(dot, mulf(t, p));
                    }
                }
                var centered_square_sum = subf(patch_square_sum, divf(mulf(patch_sum, patch_sum), count_f));
                if (centered_square_sum < 0) centered_square_sum = 0;
                if (!(centered_square_sum > 0)) return -1;
                const numerator = subf(dot, divf(mulf(patch_sum, template_sum), count_f));
                const denominator = mulf(@sqrt(centered_square_sum), template_denominator);
                const score = divf(numerator, denominator);
                const magnitude = @abs(score);
                if (!std.math.isFinite(magnitude)) return -1;
                if (magnitude > best_magnitude) {
                    best_magnitude = magnitude;
                    best_index = candidate_index;
                }
            }
            candidate_index += 1;
        }
    }

    const output = output_ptr orelse return -2;
    if (capacity < 8) return -2;
    put64(output[0..8], @intCast(best_index));
    return 8;
}
