#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxHeight = 4;
constexpr int kMaxNodes = 15;
constexpr int kMaxQueries = 4;
constexpr int kMaxWords = 41;

void fill_keys(std::array<std::int64_t, kMaxNodes + 1>& keys,
               int heap, int low, int high) {
    if (low > high) return;
    const int middle = low + (high - low) / 2;
    keys[static_cast<std::size_t>(heap)] = middle;
    fill_keys(keys, 2 * heap, low, middle - 1);
    fill_keys(keys, 2 * heap + 1, middle + 1, high);
}

void emit_layout(std::array<std::int64_t, kMaxNodes>& order, int& used,
                 int root, int height) {
    if (height == 1) {
        order[static_cast<std::size_t>(used++)] = root;
        return;
    }
    const int top_height = height / 2;
    const int bottom_height = height - top_height;
    emit_layout(order, used, root, top_height);
    const int bottom_count = 1 << top_height;
    for (int offset = 0; offset < bottom_count; ++offset)
        emit_layout(order, used, root * bottom_count + offset, bottom_height);
}
} // namespace

extern "C" std::int64_t van_emde_boas_layout_search(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 2 + kMaxQueries + 1) return -1;
    const std::int64_t height_value = input[0];
    const std::int64_t query_value = input[1];
    if (height_value < 1 || height_value > kMaxHeight ||
        query_value < 0 || query_value > kMaxQueries) return -1;
    const int height = static_cast<int>(height_value);
    const int query_count = static_cast<int>(query_value);
    if (length != static_cast<std::size_t>(2 + query_count)) return -1;
    const int node_count = (1 << height) - 1;
    for (int i = 0; i < query_count; ++i)
        if (input[2 + i] < -1 || input[2 + i] > node_count) return -1;

    std::array<std::int64_t, kMaxNodes> order{};
    std::array<std::int64_t, kMaxNodes + 1> keys{};
    std::array<std::int64_t, kMaxNodes + 1> slots{};
    std::array<std::int64_t, kMaxWords> staged{};
    int used = 0;
    emit_layout(order, used, 1, height);
    fill_keys(keys, 1, 0, node_count - 1);
    for (int slot = 0; slot < node_count; ++slot)
        slots[static_cast<std::size_t>(order[static_cast<std::size_t>(slot)])] = slot;

    int out = 0;
    staged[static_cast<std::size_t>(out++)] = node_count;
    for (int slot = 0; slot < node_count; ++slot)
        staged[static_cast<std::size_t>(out++)] = order[static_cast<std::size_t>(slot)];
    staged[static_cast<std::size_t>(out++)] = query_count;
    for (int query = 0; query < query_count; ++query) {
        const std::int64_t key = input[2 + query];
        int heap = 1;
        const int path_start = out++;
        int path_length = 0;
        std::int64_t found = -1;
        while (heap <= node_count) {
            staged[static_cast<std::size_t>(out++)] = slots[static_cast<std::size_t>(heap)];
            ++path_length;
            if (key == keys[static_cast<std::size_t>(heap)]) {
                found = heap;
                break;
            }
            heap = key < keys[static_cast<std::size_t>(heap)] ? 2 * heap : 2 * heap + 1;
        }
        staged[static_cast<std::size_t>(path_start)] = path_length;
        staged[static_cast<std::size_t>(out++)] = found;
    }
    const std::size_t required = static_cast<std::size_t>(out) * 8;
    if (output == nullptr || capacity < required) return -2;
    for (int word = 0; word < out; ++word) {
        const auto bits = static_cast<std::uint64_t>(staged[static_cast<std::size_t>(word)]);
        for (int byte = 0; byte < 8; ++byte)
            output[static_cast<std::size_t>(word) * 8 + static_cast<std::size_t>(byte)] =
                static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<std::int64_t>(required);
}
