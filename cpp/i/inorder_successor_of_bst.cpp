#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxNodes = 64;
constexpr std::size_t kMaxInputLength = 67;
}

extern "C" std::int64_t inorder_successor_of_bst(const std::int64_t *input,
                                                   std::size_t length) noexcept
{
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const std::int64_t count_value = input[0], target = input[1];
    if (count_value < 0 || count_value > 64 || target < 1 || target > 2'147'483'647 ||
        length != static_cast<std::size_t>(count_value) + 2) return -1;

    const auto count = static_cast<std::size_t>(count_value);
    std::int64_t keys[kMaxNodes];
    int left[kMaxNodes], right[kMaxNodes];
    int root = -1;
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t key = input[index + 2];
        if (key < 1 || key > 2'147'483'647) return -1;
        for (std::size_t previous = 0; previous < index; ++previous) {
            if (keys[previous] == key) return -1;
        }
        keys[index] = key;
        left[index] = right[index] = -1;
        const int node = static_cast<int>(index);
        if (root < 0) {
            root = node;
            continue;
        }
        int current = root;
        for (;;) {
            if (key <= keys[current]) {
                if (left[current] < 0) {
                    left[current] = node;
                    break;
                }
                current = left[current];
            } else {
                if (right[current] < 0) {
                    right[current] = node;
                    break;
                }
                current = right[current];
            }
        }
    }

    int current = root;
    while (current >= 0 && keys[current] != target) {
        current = target > keys[current] ? right[current] : left[current];
    }
    if (current < 0) return 0;

    if (right[current] >= 0) {
        int successor = right[current];
        while (left[successor] >= 0) successor = left[successor];
        return keys[successor];
    }
    int successor = -1;
    int ancestor = root;
    while (ancestor >= 0 && ancestor != current) {
        if (keys[current] < keys[ancestor]) {
            successor = ancestor;
            ancestor = left[ancestor];
        } else {
            ancestor = right[ancestor];
        }
    }
    return successor < 0 ? 0 : keys[successor];
}
