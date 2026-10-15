/// Area covered by the union of two axis-aligned rectangles.
const COORDINATE_LIMIT: i64 = 1_000_000_000;

export fn rectangle_union_area(coordinates: [*c]const i64, length: usize) i64 {
    if (coordinates == null or length != 8) return -1;
    for (0..8) |index| {
        if (coordinates[index] < -COORDINATE_LIMIT or coordinates[index] > COORDINATE_LIMIT) return -1;
    }
    const ax1, const ay1 = .{ coordinates[0], coordinates[1] };
    const ax2, const ay2 = .{ coordinates[2], coordinates[3] };
    const bx1, const by1 = .{ coordinates[4], coordinates[5] };
    const bx2, const by2 = .{ coordinates[6], coordinates[7] };
    if (ax1 >= ax2 or ay1 >= ay2 or bx1 >= bx2 or by1 >= by2) return -1;
    const area_a = (ax2 - ax1) * (ay2 - ay1);
    const area_b = (bx2 - bx1) * (by2 - by1);
    const overlap_width = @min(ax2, bx2) - @max(ax1, bx1);
    const overlap_height = @min(ay2, by2) - @max(ay1, by1);
    const overlap: i64 = if (overlap_width > 0 and overlap_height > 0)
        overlap_width * overlap_height
    else
        0;
    return area_a + area_b - overlap;
}
