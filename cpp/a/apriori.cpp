#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_TRANSACTIONS = 64;
constexpr std::size_t MAX_ITEMSETS = 1u << 12;
constexpr std::int64_t SUPPORT_SCALE = 1'000'000;

unsigned item_count(std::uint32_t mask) noexcept
{
    unsigned count = 0;
    while (mask != 0) {
        count += mask & 1u;
        mask >>= 1;
    }
    return count;
}

bool support_is_frequent(std::int64_t support, std::int64_t transaction_count,
                         std::int64_t threshold_ppm) noexcept
{
    return support * SUPPORT_SCALE >= threshold_ppm * transaction_count;
}
}

extern "C" std::int64_t apriori(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 5) return -1;
    const auto transaction_count = input[0];
    const auto items = input[1];
    const auto min_support_ppm = input[2];
    const auto min_confidence_ppm = input[3];
    if (transaction_count < 1 || transaction_count > static_cast<std::int64_t>(MAX_TRANSACTIONS) ||
        items < 1 || items > 12 || min_support_ppm < 1 || min_support_ppm > SUPPORT_SCALE ||
        min_confidence_ppm < 0 || min_confidence_ppm > SUPPORT_SCALE ||
        length != 4 + static_cast<std::size_t>(transaction_count)) return -1;

    const auto mask_limit = std::uint32_t{1} << static_cast<unsigned>(items);
    std::array<std::uint32_t, MAX_TRANSACTIONS> transactions{};
    for (std::size_t index = 0; index < static_cast<std::size_t>(transaction_count); ++index) {
        if (input[4 + index] < 0 || static_cast<std::uint64_t>(input[4 + index]) >= mask_limit) return -1;
        transactions[index] = static_cast<std::uint32_t>(input[4 + index]);
    }

    std::array<std::int64_t, MAX_ITEMSETS> supports{};
    std::array<std::uint8_t, MAX_ITEMSETS> previous{}, all_frequent{}, current{};
    for (std::uint32_t mask = 1; mask < mask_limit; mask <<= 1) {
        std::int64_t support = 0;
        for (std::size_t transaction = 0; transaction < static_cast<std::size_t>(transaction_count); ++transaction)
            support += (transactions[transaction] & mask) == mask;
        if (support_is_frequent(support, transaction_count, min_support_ppm)) {
            supports[mask] = support;
            previous[mask] = all_frequent[mask] = 1;
        }
    }

    for (unsigned size = 2; size <= static_cast<unsigned>(items); ++size) {
        current.fill(0);
        bool found = false;
        for (std::uint32_t mask = 1; mask < mask_limit; ++mask) {
            if (item_count(mask) != size) continue;
            bool all_subsets_frequent = true;
            for (unsigned item = 0; item < static_cast<unsigned>(items); ++item) {
                const auto bit = std::uint32_t{1} << item;
                if ((mask & bit) != 0 && previous[mask ^ bit] == 0) {
                    all_subsets_frequent = false;
                    break;
                }
            }
            if (!all_subsets_frequent) continue;
            std::int64_t support = 0;
            for (std::size_t transaction = 0; transaction < static_cast<std::size_t>(transaction_count); ++transaction)
                support += (transactions[transaction] & mask) == mask;
            if (support_is_frequent(support, transaction_count, min_support_ppm)) {
                supports[mask] = support;
                current[mask] = all_frequent[mask] = 1;
                found = true;
            }
        }
        previous = current;
        if (!found) break;
    }

    std::int64_t rule_count = 0;
    for (std::uint32_t mask = 1; mask < mask_limit; ++mask) {
        if (all_frequent[mask] == 0 || item_count(mask) < 2) continue;
        for (std::uint32_t antecedent = (mask - 1) & mask; antecedent != 0;
             antecedent = (antecedent - 1) & mask) {
            if (supports[mask] * SUPPORT_SCALE >= min_confidence_ppm * supports[antecedent]) ++rule_count;
        }
    }
    return rule_count;
}
