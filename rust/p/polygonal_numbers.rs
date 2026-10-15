#[no_mangle]
pub extern "C" fn polygonal_numbers(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length != 2 {
        return -1;
    }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    let num = packed[0];
    let sides = packed[1];
    if !(0..=100_000_000).contains(&num) || !(3..=64).contains(&sides) {
        return -1;
    }
    let square = num * num;
    let leading = (sides - 2) * square;
    let trailing = (sides - 4) * num;
    (leading - trailing) / 2
}
