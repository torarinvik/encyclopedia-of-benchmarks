/// Sum perimeters of almost-equilateral triangles up to the supported limit.
#[no_mangle]
pub extern "C" fn problem94(max_perimeter: i64) -> i64 {
    if !(0..=1_000_000_000).contains(&max_perimeter) {
        return -1;
    }
    let (mut previous, mut value, mut perimeter_sum, mut index, mut perimeter) = (1i64, 2i64, 0i64, 0i64, 0i64);
    while perimeter <= max_perimeter {
        perimeter_sum += perimeter;
        previous += 2 * value;
        value += previous;
        perimeter = if index % 2 == 0 { 2 * value + 2 } else { 2 * value - 2 };
        index += 1;
    }
    perimeter_sum
}
