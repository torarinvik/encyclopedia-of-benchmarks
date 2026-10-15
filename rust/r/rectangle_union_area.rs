/// Area covered by the union of two axis-aligned rectangles.
const COORDINATE_LIMIT: i64 = 1_000_000_000;

#[no_mangle]
pub extern "C" fn rectangle_union_area(coordinates: *const i64, length: usize) -> i64 {
    if coordinates.is_null() || length != 8 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(coordinates, 8) };
    if input.iter().any(|&value| !(-COORDINATE_LIMIT..=COORDINATE_LIMIT).contains(&value)) {
        return -1;
    }
    let [ax1, ay1, ax2, ay2, bx1, by1, bx2, by2]: [i64; 8] = input.try_into().unwrap();
    if ax1 >= ax2 || ay1 >= ay2 || bx1 >= bx2 || by1 >= by2 { return -1; }
    let area_a = (ax2 - ax1) * (ay2 - ay1);
    let area_b = (bx2 - bx1) * (by2 - by1);
    let overlap_width = ax2.min(bx2) - ax1.max(bx1);
    let overlap_height = ay2.min(by2) - ay1.max(by1);
    let overlap = if overlap_width > 0 && overlap_height > 0 {
        overlap_width * overlap_height
    } else { 0 };
    area_a + area_b - overlap
}
