#include <cstddef>
#include <cstdint>

static constexpr std::size_t MAX_KEYS = 64;
static constexpr std::size_t KEY_WIDTH = 4;
static void sift_down(std::uint32_t* keys, std::size_t root, std::size_t end) {
    while (root < end / 2) {
        std::size_t child = root * 2 + 1;
        if (child + 1 < end && keys[child] < keys[child + 1]) ++child;
        if (keys[root] >= keys[child]) break;
        auto t = keys[root]; keys[root] = keys[child]; keys[child] = t;
        root = child;
    }
}

extern "C" std::int64_t string_heap_sort(const std::int64_t* values, std::size_t length,
                                           std::uint8_t* output, std::size_t capacity) {
    if (values == nullptr || length < 1 || length > 1 + MAX_KEYS * KEY_WIDTH) return -1;
    const auto raw_count = values[0];
    if (raw_count < 0 || raw_count > static_cast<std::int64_t>(MAX_KEYS) ||
        length != 1 + KEY_WIDTH * static_cast<std::size_t>(raw_count)) return -1;
    const auto count = static_cast<std::size_t>(raw_count);
    std::uint32_t keys[MAX_KEYS]{};
    for (std::size_t i = 0; i < count; ++i) {
        std::uint32_t key = 0;
        for (std::size_t b = 0; b < KEY_WIDTH; ++b) {
            const auto byte = values[1 + KEY_WIDTH * i + b];
            if (byte < 0 || byte > 127) return -1;
            key = (key << 8) | static_cast<std::uint32_t>(byte);
        }
        keys[i] = key;
    }
    for (std::size_t start = count / 2; start > 0;) { --start; sift_down(keys, start, count); }
    for (std::size_t end = count; end > 1;) {
        --end; auto t = keys[0]; keys[0] = keys[end]; keys[end] = t;
        sift_down(keys, 0, end);
    }
    const std::size_t bytes = count * KEY_WIDTH;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t i = 0; i < count; ++i)
        for (std::size_t b = 0; b < KEY_WIDTH; ++b)
            output[i * KEY_WIDTH + b] = static_cast<std::uint8_t>(keys[i] >> (24 - 8 * b));
    return static_cast<std::int64_t>(bytes);
}
