// Count single-color block replacements for lengths two, three, and four.
module problem116

const max_length = i64(91)

@[export: 'problem116']
pub fn problem116(length i64) i64 {
    if length > max_length { return -1 }
    if length < 0 { return -1 }
    mut ways := [276]i64{}
    mut row_length := i64(0)
    for row_length <= length {
        mut tile_length := i64(2)
        for tile_length < 5 {
            color := tile_length - 2
            mut tile_start := i64(0)
            for tile_start < row_length - tile_length + 1 {
                suffix := row_length - tile_start - tile_length
                index := int(row_length * 3 + color)
                suffix_index := int(suffix * 3 + color)
                ways[index] += ways[suffix_index] + 1
                tile_start++
            }
            tile_length++
        }
        row_length++
    }
    return ways[int(length * 3)] + ways[int(length * 3 + 1)] + ways[int(length * 3 + 2)]
}
