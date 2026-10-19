const std = @import("std");

const min_n: i64 = -100_000;
const max_n: i64 = 100_000;
const output_bytes: usize = 72;

const Toggle = struct {
    state: bool,
    activate: *const fn (*Toggle) *Toggle,
    value: *const fn (*const Toggle) bool,
};
const NthToggle = struct {
    state: bool,
    count_max: i32,
    counter: i32,
    activate: *const fn (*NthToggle) *NthToggle,
    value: *const fn (*const NthToggle) bool,
};

fn toggleActivate(toggle: *Toggle) *Toggle {
    toggle.state = !toggle.state;
    return toggle;
}
fn toggleValue(toggle: *const Toggle) bool { return toggle.state; }

fn nthToggleActivate(toggle: *NthToggle) *NthToggle {
    toggle.counter += 1;
    if (toggle.counter >= toggle.count_max) {
        toggle.state = !toggle.state;
        toggle.counter = 0;
    }
    return toggle;
}
fn nthToggleValue(toggle: *const NthToggle) bool { return toggle.state; }

fn appendState(staged: *[output_bytes]u8, used: *usize, state: bool) void {
    const word: []const u8 = if (state) "true" else "false";
    for (word) |byte| { staged[used.*] = byte; used.* += 1; }
    staged[used.*] = '\n'; used.* += 1;
}

export fn shootout_objinst(n: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (n < min_n or n > max_n) return -1;
    if (output_opt == null or output_capacity < output_bytes) return -2;

    const allocator = std.heap.page_allocator;
    var staged: [output_bytes]u8 = undefined;
    var used: usize = 0;
    const toggle = allocator.create(Toggle) catch return -1;
    toggle.* = .{ .state = true, .activate = toggleActivate, .value = toggleValue };
    for (0..5) |_| {
        const active = toggle.activate(toggle);
        appendState(&staged, &used, toggle.value(active));
    }
    allocator.destroy(toggle);

    if (n > 0) {
        var index: i64 = 0;
        while (index < n) : (index += 1) {
            const extra = allocator.create(Toggle) catch return -1;
            extra.* = .{ .state = true, .activate = toggleActivate, .value = toggleValue };
            allocator.destroy(extra);
        }
    }

    staged[used] = '\n';
    used += 1;
    const nth_toggle = allocator.create(NthToggle) catch return -1;
    nth_toggle.* = .{
        .state = true, .count_max = 3, .counter = 0,
        .activate = nthToggleActivate, .value = nthToggleValue,
    };
    for (0..8) |_| {
        const active = nth_toggle.activate(nth_toggle);
        appendState(&staged, &used, nth_toggle.value(active));
    }
    allocator.destroy(nth_toggle);

    if (n > 0) {
        var index: i64 = 0;
        while (index < n) : (index += 1) {
            const extra = allocator.create(NthToggle) catch return -1;
            extra.* = .{
                .state = true, .count_max = 3, .counter = 0,
                .activate = nthToggleActivate, .value = nthToggleValue,
            };
            allocator.destroy(extra);
        }
    }

    if (used != output_bytes) return -1;
    const output = output_opt.?;
    for (0..used) |index| output[index] = staged[index];
    return @intCast(used);
}
