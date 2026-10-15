#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_ITEMS 12
#define MAX_TRANSACTIONS 64
#define MAX_ITEMSETS (1u << MAX_ITEMS)
#define SUPPORT_SCALE INT64_C(1000000)

static unsigned item_count(uint32_t mask)
{
    unsigned count = 0;
    while (mask != 0) {
        count += mask & 1u;
        mask >>= 1;
    }
    return count;
}

static int support_is_frequent(int64_t support, int64_t transaction_count, int64_t threshold_ppm)
{
    return support * SUPPORT_SCALE >= threshold_ppm * transaction_count;
}

int64_t apriori(const int64_t *input, size_t length)
{
    if (input == NULL || length < 5) return -1;
    const int64_t transaction_count = input[0];
    const int64_t items = input[1];
    const int64_t min_support_ppm = input[2];
    const int64_t min_confidence_ppm = input[3];
    if (transaction_count < 1 || transaction_count > MAX_TRANSACTIONS || items < 1 || items > MAX_ITEMS ||
        min_support_ppm < 1 || min_support_ppm > SUPPORT_SCALE ||
        min_confidence_ppm < 0 || min_confidence_ppm > SUPPORT_SCALE ||
        length != 4 + (size_t)transaction_count) return -1;

    const uint32_t mask_limit = 1u << (unsigned)items;
    uint32_t transactions[MAX_TRANSACTIONS];
    for (size_t index = 0; index < (size_t)transaction_count; ++index) {
        if (input[4 + index] < 0 || (uint64_t)input[4 + index] >= mask_limit) return -1;
        transactions[index] = (uint32_t)input[4 + index];
    }

    int64_t supports[MAX_ITEMSETS] = {0};
    uint8_t previous[MAX_ITEMSETS] = {0};
    uint8_t all_frequent[MAX_ITEMSETS] = {0};
    uint8_t current[MAX_ITEMSETS];
    for (uint32_t mask = 1; mask < mask_limit; mask <<= 1) {
        int64_t support = 0;
        for (size_t transaction = 0; transaction < (size_t)transaction_count; ++transaction)
            support += (transactions[transaction] & mask) == mask;
        if (support_is_frequent(support, transaction_count, min_support_ppm)) {
            supports[mask] = support;
            previous[mask] = 1;
            all_frequent[mask] = 1;
        }
    }

    for (unsigned size = 2; size <= (unsigned)items; ++size) {
        memset(current, 0, sizeof(current));
        int found = 0;
        for (uint32_t mask = 1; mask < mask_limit; ++mask) {
            if (item_count(mask) != size) continue;
            int all_subsets_frequent = 1;
            for (unsigned item = 0; item < (unsigned)items; ++item) {
                const uint32_t bit = 1u << item;
                if ((mask & bit) != 0 && !previous[mask ^ bit]) {
                    all_subsets_frequent = 0;
                    break;
                }
            }
            if (!all_subsets_frequent) continue;
            int64_t support = 0;
            for (size_t transaction = 0; transaction < (size_t)transaction_count; ++transaction)
                support += (transactions[transaction] & mask) == mask;
            if (support_is_frequent(support, transaction_count, min_support_ppm)) {
                supports[mask] = support;
                current[mask] = 1;
                all_frequent[mask] = 1;
                found = 1;
            }
        }
        memcpy(previous, current, sizeof(previous));
        if (!found) break;
    }

    int64_t rule_count = 0;
    for (uint32_t mask = 1; mask < mask_limit; ++mask) {
        if (!all_frequent[mask] || item_count(mask) < 2) continue;
        for (uint32_t antecedent = (mask - 1) & mask; antecedent != 0;
             antecedent = (antecedent - 1) & mask) {
            const int64_t joint_support = supports[mask];
            const int64_t antecedent_support = supports[antecedent];
            if (joint_support * SUPPORT_SCALE >= min_confidence_ppm * antecedent_support)
                rule_count++;
        }
    }
    return rule_count;
}
