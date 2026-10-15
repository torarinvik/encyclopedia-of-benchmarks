module rectangle_union_area;

const COORDINATE_LIMIT = 1000000000;

// Area covered by the union of two axis-aligned rectangles.
fn long rectangle_union_area(long* coordinates, usz length) @export("rectangle_union_area") {
    if (coordinates == null || length != 8) { return -1; }
    for (usz index = 0; index < 8; index++) {
        if (coordinates[index] < -COORDINATE_LIMIT || coordinates[index] > COORDINATE_LIMIT) { return -1; }
    }
    long ax1 = coordinates[0]; long ay1 = coordinates[1];
    long ax2 = coordinates[2]; long ay2 = coordinates[3];
    long bx1 = coordinates[4]; long by1 = coordinates[5];
    long bx2 = coordinates[6]; long by2 = coordinates[7];
    if (ax1 >= ax2 || ay1 >= ay2 || bx1 >= bx2 || by1 >= by2) { return -1; }
    long area_a = (ax2 - ax1) * (ay2 - ay1);
    long area_b = (bx2 - bx1) * (by2 - by1);
    long overlap_width = (ax2 < bx2 ? ax2 : bx2) - (ax1 > bx1 ? ax1 : bx1);
    long overlap_height = (ay2 < by2 ? ay2 : by2) - (ay1 > by1 ? ay1 : by1);
    long overlap = overlap_width > 0 && overlap_height > 0 ? overlap_width * overlap_height : 0;
    return area_a + area_b - overlap;
}
