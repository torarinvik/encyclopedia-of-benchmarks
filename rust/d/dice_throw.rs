const MAX_FACES: i64 = 8;
const MAX_DICE: i64 = 8;
const MAX_TARGET: i64 = 64;

#[no_mangle]
pub extern "C" fn dice_throw(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 3 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, 3) };
    let faces_value = input[0];
    let dice_value = input[1];
    let target_value = input[2];
    if !(1..=MAX_FACES).contains(&faces_value) || !(1..=MAX_DICE).contains(&dice_value) ||
        !(0..=MAX_TARGET).contains(&target_value) { return -1; }
    let faces = faces_value as usize;
    let dice = dice_value as usize;
    let target = target_value as usize;

    let mut table = [[0i64; 65]; 9];
    for total in 1..=faces.min(target) { table[1][total] = 1; }
    for die in 2..=dice {
        for total in 1..=target {
            for face in 1..=total.saturating_sub(1).min(faces) {
                table[die][total] += table[die - 1][total - face];
            }
        }
    }
    table[dice][target]
}
