const MIN_N: i64 = -100_000;
const MAX_N: i64 = 100_000;
const OUTPUT_BYTES: usize = 72;

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

fn append_state(staged: &mut [u8; OUTPUT_BYTES], used: &mut usize, state: bool) {
    let word: &[u8] = if state { b"true" } else { b"false" };
    for &byte in word { staged[*used] = byte; *used += 1; }
    staged[*used] = b'\n'; *used += 1;
}

#[no_mangle]
pub unsafe extern "C" fn shootout_objinst(n: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(MIN_N..=MAX_N).contains(&n) { return -1; }
    if output.is_null() || output_capacity < OUTPUT_BYTES { return -2; }

    let mut staged = [0_u8; OUTPUT_BYTES];
    let mut used = 0;
    let mut toggle = Box::new(Toggle { state: true, activate: toggle_activate, value: toggle_value });
    for _ in 0..5 {
        let activate = toggle.activate;
        let active = activate(&mut toggle);
        let value = toggle.value;
        append_state(&mut staged, &mut used, value(active));
    }
    drop(toggle);

    if n > 0 {
        for _ in 0..n {
            let extra = Box::new(Toggle { state: true, activate: toggle_activate, value: toggle_value });
            drop(extra);
        }
    }

    staged[used] = b'\n';
    used += 1;
    let mut nth_toggle = Box::new(NthToggle {
        state: true, count_max: 3, counter: 0,
        activate: nth_toggle_activate, value: nth_toggle_value,
    });
    for _ in 0..8 {
        let activate = nth_toggle.activate;
        let active = activate(&mut nth_toggle);
        let value = nth_toggle.value;
        append_state(&mut staged, &mut used, value(active));
    }
    drop(nth_toggle);

    if n > 0 {
        for _ in 0..n {
            let extra = Box::new(NthToggle {
                state: true, count_max: 3, counter: 0,
                activate: nth_toggle_activate, value: nth_toggle_value,
            });
            drop(extra);
        }
    }

    if used != OUTPUT_BYTES { return -1; }
    for index in 0..used { *output.add(index) = staged[index]; }
    used as i64
}
