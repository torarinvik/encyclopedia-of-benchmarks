// Count single-color block replacements for lengths two, three, and four.
package problem116

MAX_LENGTH :: i64(91)

@(export)
problem116 :: proc "c" (length: i64) -> i64 {
    if length > MAX_LENGTH do return -1
    if length < 0 do return -1
    ways: [276]i64 = {}
    for row_length := i64(0); row_length <= length; row_length += 1 {
        for tile_length := i64(2); tile_length < 5; tile_length += 1 {
            color := tile_length - 2
            for tile_start := i64(0); tile_start < row_length - tile_length + 1; tile_start += 1 {
                suffix := row_length - tile_start - tile_length
                index := usz(row_length * 3 + color)
                suffix_index := usz(suffix * 3 + color)
                ways[index] += ways[suffix_index] + 1
            }
        }
    }
    return ways[usz(length * 3)] + ways[usz(length * 3 + 1)] + ways[usz(length * 3 + 2)]
}
