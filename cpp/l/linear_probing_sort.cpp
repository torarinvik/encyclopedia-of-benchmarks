#include <cstddef>
#include <cstdint>
#include <cstdlib>

namespace {
constexpr std::size_t max_length = 1024;

void insertion_sort(std::int64_t* values, std::size_t length) noexcept {
    for (std::size_t index = 1; index < length; ++index) {
        const auto key = values[index];
        auto position = index;
        while (position > 0 && values[position - 1] > key) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = key;
    }
}
}

extern "C" void linear_probing_sort(std::int64_t* values, std::size_t length) noexcept {
    if (values == nullptr || length < 2) return;
    if (length > max_length) {
        insertion_sort(values, length);
        return;
    }

    auto minimum = values[0];
    auto maximum = values[0];
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 255) {
            insertion_sort(values, length);
            return;
        }
        if (values[index] < minimum) minimum = values[index];
        if (values[index] > maximum) maximum = values[index];
    }

    const std::size_t main_slots = 256 * (length + 1) + 1;
    const std::size_t table_length = main_slots + length;
    auto* table = static_cast<std::int64_t*>(std::calloc(table_length, sizeof(std::int64_t)));
    if (table == nullptr) {
        insertion_sort(values, length);
        return;
    }

    const auto span = maximum - minimum;
    for (std::size_t index = 0; index < length; ++index) {
        const auto home = span == 0 ? std::size_t{0} :
            static_cast<std::size_t>((values[index] - minimum) *
                                     static_cast<std::int64_t>(main_slots - 1) / span);
        auto slot = home;
        while (table[slot] != 0) ++slot;
        table[slot] = values[index] + 1;
    }
    std::size_t output = 0;
    for (std::size_t slot = 0; slot < table_length; ++slot) {
        if (table[slot] != 0) values[output++] = table[slot] - 1;
    }
    std::free(table);
}
