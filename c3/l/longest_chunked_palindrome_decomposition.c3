module chunked_pal_decomp;

// Count chunks by peeling the shortest matching prefix and suffix.
fn long longest_chunked_palindrome_decomposition(long* text, usz length) @export("longest_chunked_palindrome_decomposition")
{
    if (length > 128) return -1;
    for (usz index = 0; index < length; index++) {
        if (text[index] < 1 || text[index] > 127) return -1;
    }
    usz left = 0;
    usz right = length;
    long chunks = 0;
    while (left < right) {
        usz remaining = right - left;
        usz size = 1;
        bool matched = false;
        while (size <= remaining / 2 && !matched) {
            bool equal = true;
            usz offset = 0;
            while (offset < size && equal) {
                if (text[left + offset] != text[right - size + offset]) equal = false;
                offset++;
            }
            if (equal) {
                chunks += 2;
                left += size;
                right -= size;
                matched = true;
            } else {
                size++;
            }
        }
        if (!matched) return chunks + 1;
    }
    return chunks;
}
