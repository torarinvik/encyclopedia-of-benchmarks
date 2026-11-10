package valid_anagram

import "core:c"

// Compare lowercase ASCII strings by their letter frequencies.
@(export)
valid_anagram :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if length < 2 || length > 2050 do return -1
    first, second := u64(input[0]), u64(input[1])
    if first > 1024 || second > 1024 || u64(length) != 2 + first + second do return -1
    if first != second {
        for i in 2..<int(length) {
            if u64(input[i]) - 97 > 25 do return -1
        }
        return 0
    }

    counts: [26]u16
    count := int(first)
    for i in 2..<2 + count {
        left, right := u64(input[i]) - 97, u64(input[i + count]) - 97
        if left > 25 || right > 25 do return -1
        if left != right {
            counts[left] += 1
            counts[right] -= 1
        }
    }
    for balance in counts {
        if balance != 0 do return 0
    }
    return 1
}
