const MIN_CALLS: i64 = -100_000;
const MAX_CALLS: i64 = 100_000;
const MAX_OUTPUT_BYTES: usize = 14;

type ToggleActivate = fn(&mut Toggle) -> &Toggle;
type ToggleValue = fn(&Toggle) -> bool;
type NthToggleActivate = fn(&mut NthToggle) -> &NthToggle;
type NthToggleValue = fn(&NthToggle) -> bool;

struct Toggle { state: bool, activate: ToggleActivate, value: ToggleValue }
struct NthToggle {
    state: bool,
    count_max: i32,
    counter: i32,
    activate: NthToggleActivate,
    value: NthToggleValue,
}

fn toggle_activate(toggle: &mut Toggle) -> &Toggle {
    toggle.state = !toggle.state;
    toggle
}
fn toggle_value(toggle: &Toggle) -> bool { toggle.state }

fn nth_toggle_activate(toggle: &mut NthToggle) -> &NthToggle {
    toggle.counter += 1;
    if toggle.counter >= toggle.count_max {
        toggle.state = !toggle.state;
        toggle.counter = 0;
    }
    toggle
}
fn nth_toggle_value(toggle: &NthToggle) -> bool { toggle.state }

fn append_state(staged: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize, state: bool) {
    let word: &[u8] = if state { b"true" } else { b"false" };
    for &byte in word { staged[*used] = byte; *used += 1; }
    staged[*used] = b'\n'; *used += 1;
    staged[*used] = b'\n'; *used += 1;
}

#[no_mangle]
pub unsafe extern "C" fn shootout_methcall(calls: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(MIN_CALLS..=MAX_CALLS).contains(&calls) { return -1; }
    if output.is_null() { return -2; }
    let mut toggle = Toggle { state: true, activate: toggle_activate, value: toggle_value };
    let mut nth_toggle = NthToggle {
        state: true, count_max: 3, counter: 0,
        activate: nth_toggle_activate, value: nth_toggle_value,
    };
    let mut toggle_result = true;
    let mut nth_result = true;
    for _ in 0..calls.max(0) {
        let activate = toggle.activate;
        let active = activate(&mut toggle);
        let value = toggle.value;
        toggle_result = value(active);
    }
    for _ in 0..calls.max(0) {
        let activate = nth_toggle.activate;
        let active = activate(&mut nth_toggle);
        let value = nth_toggle.value;
        nth_result = value(active);
    }
    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    let mut used = 0;
    append_state(&mut staged, &mut used, toggle_result);
    append_state(&mut staged, &mut used, nth_result);
    if output_capacity < used { return -2; }
    for index in 0..used { *output.add(index) = staged[index]; }
    used as i64
}
