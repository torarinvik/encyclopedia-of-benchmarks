#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_Q = 48;
constexpr std::size_t MAX_CONS = 32;
constexpr std::size_t MAX_ROOTS = 49;
constexpr std::size_t MAX_BLOCKS = 6;
constexpr std::size_t MAX_SLOTS = 63;
constexpr std::size_t MAX_PARSEABLE = 146;

struct Block {
    std::int32_t previous_block = -1;
    std::int32_t previous_offset = -1;
    std::int32_t capacity = 0;
    std::int32_t last_used = -1;
    std::int32_t base = 0;
};

struct Context {
    std::array<Block, MAX_BLOCKS> blocks{};
    std::array<std::int64_t, MAX_SLOTS> data{};
    std::array<std::int32_t, MAX_ROOTS> root_block{};
    std::array<std::int32_t, MAX_ROOTS> root_offset{};
    std::array<std::int64_t, MAX_Q> results{};
    std::int32_t block_count = 0;
    std::int32_t root_count = 1;
    std::int32_t slot_count = 0;
    std::int32_t cons_count = 0;
};

std::int64_t list_length(const Context &ctx, std::int32_t root) {
    auto block_id = ctx.root_block[static_cast<std::size_t>(root)];
    auto offset = ctx.root_offset[static_cast<std::size_t>(root)];
    std::int64_t total = 0;
    while (block_id >= 0) {
        if (block_id >= ctx.block_count || offset < 0 ||
            offset > ctx.blocks[static_cast<std::size_t>(block_id)].last_used) return -1;
        const auto &block = ctx.blocks[static_cast<std::size_t>(block_id)];
        total += static_cast<std::int64_t>(offset) + 1;
        block_id = block.previous_block;
        offset = block.previous_offset;
    }
    return total;
}

std::int64_t list_nth(const Context &ctx, std::int32_t root, std::int64_t index) {
    auto block_id = ctx.root_block[static_cast<std::size_t>(root)];
    auto offset = ctx.root_offset[static_cast<std::size_t>(root)];
    auto remaining = index;
    while (block_id >= 0) {
        if (block_id >= ctx.block_count || offset < 0 ||
            offset > ctx.blocks[static_cast<std::size_t>(block_id)].last_used) return INT64_MIN;
        const auto &block = ctx.blocks[static_cast<std::size_t>(block_id)];
        if (remaining <= offset)
            return ctx.data[static_cast<std::size_t>(block.base + offset - remaining)];
        remaining -= static_cast<std::int64_t>(offset) + 1;
        block_id = block.previous_block;
        offset = block.previous_offset;
    }
    return INT64_MIN;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) {
        output[offset + i] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
} // namespace

extern "C" std::int64_t vlist_persistent_sequence(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > MAX_PARSEABLE) return -1;
    const auto q_word = input[0];
    if (q_word < 1 || q_word > static_cast<std::int64_t>(MAX_Q) ||
        length != 1 + 3 * static_cast<std::size_t>(q_word)) return -1;
    const auto q = static_cast<std::size_t>(q_word);

    Context ctx{};
    ctx.root_block.fill(-1);
    ctx.root_offset.fill(-1);
    bool query_phase = false;
    std::size_t at = 1;
    for (std::size_t op = 0; op < q; ++op) {
        const auto tag = input[at++];
        const auto root_word = input[at++];
        const auto arg = input[at++];
        if (tag < 0 || tag > 3 || root_word < 0 || root_word >= ctx.root_count) return -1;
        const auto root = static_cast<std::int32_t>(root_word);
        if (tag == 0) {
            if (query_phase || root != ctx.root_count - 1 || ctx.cons_count >= static_cast<std::int32_t>(MAX_CONS) ||
                arg < -1'000'000 || arg > 1'000'000) return -1;
            auto block_id = ctx.root_block[static_cast<std::size_t>(root)];
            auto offset = ctx.root_offset[static_cast<std::size_t>(root)];
            if (block_id < 0) {
                if (ctx.cons_count != 0 || ctx.block_count != 0 || ctx.slot_count >= static_cast<std::int32_t>(MAX_SLOTS)) return -1;
                auto &block = ctx.blocks[static_cast<std::size_t>(ctx.block_count)];
                block.previous_block = -1;
                block.previous_offset = -1;
                block.capacity = 1;
                block.last_used = 0;
                block.base = ctx.slot_count++;
                ctx.data[static_cast<std::size_t>(block.base)] = arg;
                block_id = ctx.block_count++;
                offset = 0;
            } else {
                if (block_id >= ctx.block_count || offset != ctx.blocks[static_cast<std::size_t>(block_id)].last_used) return -1;
                auto &block = ctx.blocks[static_cast<std::size_t>(block_id)];
                if (offset + 1 < block.capacity) {
                    ++offset;
                    ctx.data[static_cast<std::size_t>(block.base + offset)] = arg;
                    block.last_used = offset;
                } else {
                    const auto next_capacity = block.capacity * 2;
                    if (ctx.block_count >= static_cast<std::int32_t>(MAX_BLOCKS) ||
                        ctx.slot_count + next_capacity > static_cast<std::int32_t>(MAX_SLOTS)) return -1;
                    auto &next = ctx.blocks[static_cast<std::size_t>(ctx.block_count)];
                    next.previous_block = block_id;
                    next.previous_offset = offset;
                    next.capacity = next_capacity;
                    next.last_used = 0;
                    next.base = ctx.slot_count;
                    ctx.data[static_cast<std::size_t>(next.base)] = arg;
                    ctx.slot_count += next_capacity;
                    block_id = ctx.block_count++;
                    offset = 0;
                }
            }
            if (ctx.root_count >= static_cast<std::int32_t>(MAX_ROOTS)) return -1;
            ctx.root_block[static_cast<std::size_t>(ctx.root_count)] = block_id;
            ctx.root_offset[static_cast<std::size_t>(ctx.root_count)] = offset;
            ctx.results[op] = ctx.root_count++;
            ++ctx.cons_count;
        } else {
            query_phase = true;
            if (tag == 1) {
                if (arg != -1 || list_length(ctx, root) <= 0) return -1;
                auto block_id = ctx.root_block[static_cast<std::size_t>(root)];
                auto offset = ctx.root_offset[static_cast<std::size_t>(root)];
                if (offset > 0) {
                    --offset;
                } else {
                    const auto &block = ctx.blocks[static_cast<std::size_t>(block_id)];
                    block_id = block.previous_block;
                    offset = block.previous_offset;
                }
                if (ctx.root_count >= static_cast<std::int32_t>(MAX_ROOTS)) return -1;
                ctx.root_block[static_cast<std::size_t>(ctx.root_count)] = block_id;
                ctx.root_offset[static_cast<std::size_t>(ctx.root_count)] = offset;
                ctx.results[op] = ctx.root_count++;
            } else if (tag == 2) {
                const auto n = list_length(ctx, root);
                if (n < 0 || arg < 0 || arg >= n) return -1;
                const auto value = list_nth(ctx, root, arg);
                if (value == INT64_MIN) return -1;
                ctx.results[op] = value;
            } else {
                if (arg != -1) return -1;
                const auto n = list_length(ctx, root);
                if (n < 0) return -1;
                ctx.results[op] = n;
            }
        }
    }

    const auto bytes = q * 8;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t i = 0; i < q; ++i) store_i64_le(output, i * 8, ctx.results[i]);
    return static_cast<std::int64_t>(bytes);
}
