const MIN_CALLS: i64 = -100_000;
const MAX_CALLS: i64 = 100_000;
const MAX_OUTPUT_BYTES: usize = 14;

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

fn appendState(staged: *[MAX_OUTPUT_BYTES]u8, used: *usize, state: bool) void {
    const word: []const u8 = if (state) "true" else "false";
    for (word) |byte| { staged[used.*] = byte; used.* += 1; }
    staged[used.*] = '\n'; used.* += 1;
    staged[used.*] = '\n'; used.* += 1;
}

export fn shootout_methcall(calls: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (calls < MIN_CALLS or calls > MAX_CALLS) return -1;
    if (output_opt == null) return -2;
    var toggle = Toggle{ .state = true, .activate = toggleActivate, .value = toggleValue };
    var nth_toggle = NthToggle{
        .state = true, .count_max = 3, .counter = 0,
        .activate = nthToggleActivate, .value = nthToggleValue,
    };
    var toggle_result = true;
    var nth_result = true;
    var index: i64 = 0;
    while (index < calls) : (index += 1) {
        const active = toggle.activate(&toggle);
        toggle_result = toggle.value(active);
    }
    index = 0;
    while (index < calls) : (index += 1) {
        const active = nth_toggle.activate(&nth_toggle);
        nth_result = nth_toggle.value(active);
    }
    var staged: [MAX_OUTPUT_BYTES]u8 = undefined;
    var used: usize = 0;
    appendState(&staged, &used, toggle_result);
    appendState(&staged, &used, nth_result);
    if (output_capacity < used) return -2;
    const output = output_opt.?;
    for (0..used) |byte_index| output[byte_index] = staged[byte_index];
    return @intCast(used);
}
