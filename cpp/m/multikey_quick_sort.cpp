#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_strings = 32;
constexpr int max_string_length = 16;
constexpr std::size_t max_input_words = 1 + max_strings * (1 + max_string_length);
constexpr std::size_t max_parseable_input_words = max_input_words + 1;
constexpr std::size_t max_output_bytes = 4 * max_input_words;
struct StringRecord { int length{}; std::uint8_t bytes[max_string_length]{}; };

int char_at(const StringRecord& value, int depth) { return depth < value.length ? value.bytes[depth] : 0; }
int median3(int a, int b, int c) {
    if (a < b) return b < c ? b : (a < c ? c : a);
    return b > c ? b : (a < c ? a : c);
}
int compare_from_depth(const StringRecord& left, const StringRecord& right, int depth) {
    while (depth < left.length && depth < right.length && left.bytes[depth] == right.bytes[depth]) ++depth;
    const int a = char_at(left, depth), b = char_at(right, depth);
    return (a > b) - (a < b);
}
void insertion_sort(StringRecord* values, int lo, int hi, int depth) {
    for (int i = lo + 1; i < hi; ++i) {
        const auto value = values[i];
        int j = i;
        while (j > lo && compare_from_depth(values[j - 1], value, depth) > 0) { values[j] = values[j - 1]; --j; }
        values[j] = value;
    }
}
void multikey_sort(StringRecord* values, int lo, int hi, int depth) {
    const int count = hi - lo;
    if (count < 10) { insertion_sort(values, lo, hi, depth); return; }
    const int mid = lo + count / 2;
    int pivot;
    if (count > 30) {
        const int delta = count / 8;
        pivot = median3(median3(char_at(values[lo], depth), char_at(values[lo + delta], depth), char_at(values[lo + 2 * delta], depth)),
                        median3(char_at(values[mid - delta], depth), char_at(values[mid], depth), char_at(values[mid + delta], depth)),
                        median3(char_at(values[hi - 1 - 2 * delta], depth), char_at(values[hi - 1 - delta], depth), char_at(values[hi - 1], depth)));
    } else pivot = median3(char_at(values[lo], depth), char_at(values[mid], depth), char_at(values[hi - 1], depth));
    int less = lo, scan = lo, greater = hi;
    while (scan < greater) {
        const int key = char_at(values[scan], depth);
        if (key < pivot) { auto tmp = values[less]; values[less++] = values[scan]; values[scan++] = tmp; }
        else if (key > pivot) { auto tmp = values[--greater]; values[greater] = values[scan]; values[scan] = tmp; }
        else ++scan;
    }
    multikey_sort(values, lo, less, depth);
    if (pivot != 0) multikey_sort(values, less, greater, depth + 1);
    multikey_sort(values, greater, hi, depth);
}
void put_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t multikey_quick_sort(const std::int32_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_parseable_input_words) return -1;
    const auto count = input[0];
    if (count < 0 || count > max_strings) return -1;
    StringRecord values[max_strings]{};
    std::size_t pos = 1;
    for (std::int32_t i = 0; i < count; ++i) {
        if (pos >= length || input[pos] < 0 || input[pos] > max_string_length) return -1;
        const auto string_length = input[pos++];
        if (pos + static_cast<std::size_t>(string_length) > length) return -1;
        values[i].length = static_cast<int>(string_length);
        for (std::int32_t j = 0; j < string_length; ++j) {
            const auto byte = input[pos++];
            if (byte < 1 || byte > 127) return -1;
            values[i].bytes[j] = static_cast<std::uint8_t>(byte);
        }
    }
    if (pos != length) return -1;
    const auto bytes = length * 4;
    if (output == nullptr || capacity < bytes) return -2;
    multikey_sort(values, 0, count, 0);
    std::uint8_t buffer[max_output_bytes];
    std::size_t word = 0;
    put_i32_le(buffer, word++ * 4, count);
    for (std::int32_t i = 0; i < count; ++i) {
        put_i32_le(buffer, word++ * 4, values[i].length);
        for (int j = 0; j < values[i].length; ++j) put_i32_le(buffer, word++ * 4, values[i].bytes[j]);
    }
    for (std::size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return static_cast<std::int64_t>(bytes);
}
