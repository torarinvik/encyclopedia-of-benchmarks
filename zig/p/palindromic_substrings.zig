/// Count all palindromic substrings by expanding around odd and even centers.
export fn palindromic_substrings(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 1000) return -1;
    for (0..length) |index| {
        if (values[index] < 'a' or values[index] > 'z') return -1;
    }

    var count: i64 = 0;
    for (0..length) |center| {
        count += 1;
        var left = center;
        var right = center;
        while (left > 0 and right + 1 < length and values[left - 1] == values[right + 1]) {
            count += 1;
            left -= 1;
            right += 1;
        }

        left = center;
        right = center + 1;
        while (right < length and values[left] == values[right]) {
            count += 1;
            if (left == 0 or right + 1 == length) break;
            left -= 1;
            right += 1;
        }
    }
    return count;
}
