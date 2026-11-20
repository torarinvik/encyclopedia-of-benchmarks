#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_universe = 32;
constexpr std::size_t max_operations = 30;
constexpr std::size_t max_length = 63;
}

extern "C" std::int64_t sparse_set_dense_array(const std::int64_t *input,
                                                std::size_t length) {
    if (input == nullptr || length < 2 || length > max_length) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_universe)
            || input[1] < 0 || input[1] > static_cast<std::int64_t>(max_operations)) return -1;
    const auto universe = static_cast<std::size_t>(input[0]);
    const auto count = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * count) return -1;
    for (std::size_t i = 0; i < count; ++i) {
        const auto opcode = input[2 + 2 * i];
        const auto key = input[3 + 2 * i];
        if (opcode < 0 || opcode > 3 || key < 0 || key >= static_cast<std::int64_t>(universe)) return -1;
        if (opcode == 3 && key != 0) return -1;
    }

    int dense[max_universe]{};
    int sparse[max_universe];
    for (std::size_t key = 0; key < universe; ++key) sparse[key] = static_cast<int>(universe);
    std::size_t size = 0;
    std::int64_t answers = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const int opcode = static_cast<int>(input[2 + 2 * i]);
        const int key = static_cast<int>(input[3 + 2 * i]);
        const int index = sparse[key];
        const bool present = index < static_cast<int>(size) && dense[index] == key;
        std::int64_t status = 0;
        if (opcode == 0) {
            if (!present) {
                dense[size] = key;
                sparse[key] = static_cast<int>(size);
                ++size;
                status = 1;
            }
        } else if (opcode == 1) {
            if (present) {
                const int last = dense[size - 1];
                dense[index] = last;
                sparse[last] = index;
                --size;
                status = 1;
            }
        } else if (opcode == 2) {
            status = present;
        } else {
            status = size != 0;
            size = 0;
        }
        answers = (answers << 1) | status;
    }
    std::int64_t final_mask = 0;
    for (std::size_t i = 0; i < size; ++i) final_mask |= std::int64_t{1} << dense[i];
    return (final_mask << count) | answers;
}
