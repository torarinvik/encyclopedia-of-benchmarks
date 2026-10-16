#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_NAMES = 6000;
constexpr std::size_t MAX_NAME_LENGTH = 19;
constexpr std::size_t MAX_INPUT_LENGTH = 100001;

int compare_names(const std::int64_t *input, const std::size_t *offsets,
                  const std::size_t *name_lengths, std::size_t first,
                  std::size_t second) noexcept
{
    const std::size_t first_length = name_lengths[first];
    const std::size_t second_length = name_lengths[second];
    const std::size_t shared_length = first_length < second_length ? first_length : second_length;
    for (std::size_t index = 0; index < shared_length; ++index) {
        const std::int64_t first_letter = input[offsets[first] + index];
        const std::int64_t second_letter = input[offsets[second] + index];
        if (first_letter < second_letter) return -1;
        if (first_letter > second_letter) return 1;
    }
    if (first_length < second_length) return -1;
    if (first_length > second_length) return 1;
    return 0;
}
}

extern "C" std::int64_t problem22(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const std::int64_t raw_count = input[0];
    if (raw_count < 0 || raw_count > static_cast<std::int64_t>(MAX_NAMES)) return -1;
    const std::size_t count = static_cast<std::size_t>(raw_count);
    std::size_t offsets[MAX_NAMES]{};
    std::size_t name_lengths[MAX_NAMES]{};
    std::size_t order[MAX_NAMES]{};
    std::size_t cursor = 1;
    for (std::size_t name = 0; name < count; ++name) {
        if (cursor >= length) return -1;
        const std::int64_t raw_name_length = input[cursor++];
        if (raw_name_length < 1 || raw_name_length > static_cast<std::int64_t>(MAX_NAME_LENGTH)) return -1;
        const std::size_t name_length = static_cast<std::size_t>(raw_name_length);
        if (name_length > length - cursor) return -1;
        offsets[name] = cursor;
        name_lengths[name] = name_length;
        for (std::size_t letter = 0; letter < name_length; ++letter) {
            if (input[cursor + letter] < 1 || input[cursor + letter] > 26) return -1;
        }
        cursor += name_length;
        order[name] = name;
    }
    if (cursor != length) return -1;

    constexpr std::size_t gaps[] = {701, 301, 132, 57, 23, 10, 4, 1};
    for (const std::size_t gap : gaps) {
        if (gap >= count) continue;
        for (std::size_t index = gap; index < count; ++index) {
            const std::size_t key = order[index];
            std::size_t position = index;
            while (position >= gap &&
                   compare_names(input, offsets, name_lengths, order[position - gap], key) > 0) {
                order[position] = order[position - gap];
                position -= gap;
            }
            order[position] = key;
        }
    }

    std::int64_t total = 0;
    for (std::size_t position = 0; position < count; ++position) {
        const std::size_t name = order[position];
        std::int64_t score = 0;
        for (std::size_t letter = 0; letter < name_lengths[name]; ++letter) {
            score += input[offsets[name] + letter];
        }
        total += static_cast<std::int64_t>(position + 1) * score;
    }
    return total;
}
