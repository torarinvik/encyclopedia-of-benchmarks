/// Count chunks by peeling the shortest matching prefix and suffix.
export fn longest_chunked_palindrome_decomposition(text: [*]const i64, length: usize) i64 {
    if (length > 128) return -1;
    if (length > 0) {
        for (0..length) |index| {
            if (text[index] < 1 or text[index] > 127) return -1;
        }
    }
    var left: usize = 0;
    var right = length;
    var chunks: i64 = 0;
    while (left < right) {
        const remaining = right - left;
        var matched = false;
        var size: usize = 1;
        while (size <= remaining / 2 and !matched) : (size += 1) {
            var equal = true;
            for (0..size) |offset| {
                if (text[left + offset] != text[right - size + offset]) { equal = false; break; }
            }
            if (equal) {
                chunks += 2;
                left += size;
                right -= size;
                matched = true;
            }
        }
        if (!matched) return chunks + 1;
    }
    return chunks;
}
