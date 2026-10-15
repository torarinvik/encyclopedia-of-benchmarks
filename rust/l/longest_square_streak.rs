const MAX_INPUT_LENGTH: usize = 100_000;
const MAX_VALUE: usize = 100_000;
const REQUIRED_WORKSPACE: usize = 4 * (MAX_VALUE + 1);

unsafe fn read_state(workspace: *const u8, value: usize) -> i64 {
    let position = 4 * value;
    i64::from(*workspace.add(position)) |
        (i64::from(*workspace.add(position + 1)) << 8) |
        (i64::from(*workspace.add(position + 2)) << 16) |
        (i64::from(*workspace.add(position + 3)) << 24)
}

unsafe fn write_state(workspace: *mut u8, value: usize, state: i64) {
    let encoded = state as i32 as u32;
    let position = 4 * value;
    *workspace.add(position) = encoded as u8;
    *workspace.add(position + 1) = (encoded >> 8) as u8;
    *workspace.add(position + 2) = (encoded >> 16) as u8;
    *workspace.add(position + 3) = (encoded >> 24) as u8;
}

unsafe fn streak_from(workspace: *mut u8, value: usize) -> i64 {
    let state = read_state(workspace, value);
    if state > 1 { return state - 1; }
    let mut chain_length = 1i64;
    let square = (value as u64) * (value as u64);
    if square <= MAX_VALUE as u64 && read_state(workspace, square as usize) != 0 {
        chain_length += streak_from(workspace, square as usize);
    }
    write_state(workspace, value, chain_length + 1);
    chain_length
}

#[no_mangle]
pub unsafe extern "C" fn longest_square_streak(
    values: *const i64,
    length: usize,
    workspace: *mut u8,
    workspace_capacity: usize,
) -> i64 {
    if values.is_null() || length < 3 || length > MAX_INPUT_LENGTH + 1 { return -1; }
    let count_arg = *values;
    if !(2..=MAX_INPUT_LENGTH as i64).contains(&count_arg) || length != count_arg as usize + 1 {
        return -1;
    }
    let count = count_arg as usize;
    for index in 0..count {
        let value = *values.add(index + 1);
        if !(2..=MAX_VALUE as i64).contains(&value) { return -1; }
    }
    if workspace.is_null() || workspace_capacity < REQUIRED_WORKSPACE { return -2; }
    core::ptr::write_bytes(workspace, 0, REQUIRED_WORKSPACE);
    for index in 0..count {
        write_state(workspace, *values.add(index + 1) as usize, 1);
    }
    let mut longest = 1i64;
    for index in 0..count {
        longest = longest.max(streak_from(workspace, *values.add(index + 1) as usize));
    }
    if longest >= 2 { longest } else { -1 }
}
