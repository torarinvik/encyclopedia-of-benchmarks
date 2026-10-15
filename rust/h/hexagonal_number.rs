/// Return the nth hexagonal number for a JS-safe positive index.
#[no_mangle]
pub extern "C" fn hexagonal_number(number: i64) -> i64 {
    if !(1..=67_108_864).contains(&number) { return -1; }
    number * (2 * number - 1)
}
