/* Area covered by the union of two axis-aligned rectangles. */
#include <stddef.h>
#include <stdint.h>

#define COORDINATE_LIMIT INT64_C(1000000000)

int64_t rectangle_union_area(const int64_t *coordinates, size_t length)
{
    if (coordinates == NULL || length != 8) return -1;
    for (size_t index = 0; index < 8; ++index)
        if (coordinates[index] < -COORDINATE_LIMIT || coordinates[index] > COORDINATE_LIMIT)
            return -1;

    const int64_t ax1 = coordinates[0], ay1 = coordinates[1];
    const int64_t ax2 = coordinates[2], ay2 = coordinates[3];
    const int64_t bx1 = coordinates[4], by1 = coordinates[5];
    const int64_t bx2 = coordinates[6], by2 = coordinates[7];
    if (ax1 >= ax2 || ay1 >= ay2 || bx1 >= bx2 || by1 >= by2) return -1;

    const int64_t area_a = (ax2 - ax1) * (ay2 - ay1);
    const int64_t area_b = (bx2 - bx1) * (by2 - by1);
    const int64_t overlap_width = (ax2 < bx2 ? ax2 : bx2) - (ax1 > bx1 ? ax1 : bx1);
    const int64_t overlap_height = (ay2 < by2 ? ay2 : by2) - (ay1 > by1 ? ay1 : by1);
    const int64_t overlap = overlap_width > 0 && overlap_height > 0
        ? overlap_width * overlap_height : 0;
    return area_a + area_b - overlap;
}
