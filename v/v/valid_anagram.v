module valid_anagram

// Compare lowercase ASCII strings by their letter frequencies.
@[export: 'valid_anagram']
pub fn valid_anagram(input &i64, length usize) i64 {
    if length < 2 || length > 2050 { return -1 }
    first := u64(unsafe { input[0] })
    second := u64(unsafe { input[1] })
    if first > 1024 || second > 1024 || u64(length) != 2 + first + second { return -1 }
    if first != second {
        for i in 2 .. length {
            if u64(unsafe { input[i] }) - 97 > 25 { return -1 }
        }
        return 0
    }

    mut counts := [26]u16{}
    count := usize(first)
    for i in 2 .. 2 + count {
        left := u64(unsafe { input[i] }) - 97
        right := u64(unsafe { input[i + count] }) - 97
        if left > 25 || right > 25 { return -1 }
        if left != right {
            counts[left]++
            counts[right]--
        }
    }
    for balance in counts {
        if balance != 0 { return 0 }
    }
    return 1
}
