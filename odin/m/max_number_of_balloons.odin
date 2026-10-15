package max_number_of_balloons

import "core:c"

// Count how many copies of balloon the text can supply.
@(export)
max_number_of_balloons :: proc "c" (text: [^]i64, length: c.size_t) -> i64 {
    if length > 256 do return -1
    b := i64(0)
    a := i64(0)
    l := i64(0)
    o := i64(0)
    n := i64(0)
    for index := 0; index < int(length); index += 1 {
        value := text[index]
        if value < 97 || value > 122 do return -1
        if value == 98 do b += 1
        else if value == 97 do a += 1
        else if value == 108 do l += 1
        else if value == 111 do o += 1
        else if value == 110 do n += 1
    }
    l /= 2
    o /= 2
    minimum := min(b, a)
    minimum = min(minimum, l)
    minimum = min(minimum, o)
    minimum = min(minimum, n)
    return minimum
}
