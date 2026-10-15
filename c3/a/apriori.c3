module apriori;

const usz MAX_TRANSACTIONS = 64;
const usz MAX_ITEMS = 12;
const usz MAX_ITEMSETS = 4096;
const long SUPPORT_SCALE = 1000000;

fn usz item_count(long mask) {
    usz count = 0;
    while (mask != 0) {
        count += (usz)(mask & 1);
        mask >>= 1;
    }
    return count;
}

fn bool support_is_frequent(long support, long transaction_count, long threshold_ppm) {
    return support * SUPPORT_SCALE >= threshold_ppm * transaction_count;
}

fn long apriori(long* input, usz length) @export("apriori") {
    if (input == null || length < 5) return -1;
    long transaction_count = input[0];
    long items = input[1];
    long min_support_ppm = input[2];
    long min_confidence_ppm = input[3];
    if (transaction_count < 1 || transaction_count > 64 || items < 1 || items > 12 ||
        min_support_ppm < 1 || min_support_ppm > SUPPORT_SCALE ||
        min_confidence_ppm < 0 || min_confidence_ppm > SUPPORT_SCALE ||
        length != 4 + (usz)transaction_count) return -1;

    long mask_limit = 1L << (int)items;
    long[MAX_TRANSACTIONS] transactions;
    for (usz i = 0; i < MAX_TRANSACTIONS; i++) transactions[i] = 0;
    for (usz i = 0; i < (usz)transaction_count; i++) {
        if (input[4 + i] < 0 || input[4 + i] >= mask_limit) return -1;
        transactions[i] = input[4 + i];
    }

    long[MAX_ITEMSETS] supports;
    bool[MAX_ITEMSETS] previous;
    bool[MAX_ITEMSETS] all_frequent;
    bool[MAX_ITEMSETS] current;
    for (usz i = 0; i < MAX_ITEMSETS; i++) {
        supports[i] = 0;
        previous[i] = false;
        all_frequent[i] = false;
        current[i] = false;
    }
    for (long mask = 1; mask < mask_limit; mask <<= 1) {
        long support = 0;
        for (usz transaction = 0; transaction < (usz)transaction_count; transaction++) {
            if ((transactions[transaction] & mask) == mask) support++;
        }
        if (support_is_frequent(support, transaction_count, min_support_ppm)) {
            usz index = (usz)mask;
            supports[index] = support;
            previous[index] = true;
            all_frequent[index] = true;
        }
    }

    for (usz size = 2; size <= (usz)items; size++) {
        for (usz index = 0; index < MAX_ITEMSETS; index++) current[index] = false;
        bool found = false;
        for (long mask = 1; mask < mask_limit; mask++) {
            if (item_count(mask) != size) continue;
            bool all_subsets_frequent = true;
            for (usz item = 0; item < (usz)items; item++) {
                long bit = 1L << (int)item;
                if ((mask & bit) != 0 && !previous[(usz)(mask ^ bit)]) {
                    all_subsets_frequent = false;
                    break;
                }
            }
            if (!all_subsets_frequent) continue;
            long support = 0;
            for (usz transaction = 0; transaction < (usz)transaction_count; transaction++) {
                if ((transactions[transaction] & mask) == mask) support++;
            }
            if (support_is_frequent(support, transaction_count, min_support_ppm)) {
                usz index = (usz)mask;
                supports[index] = support;
                current[index] = true;
                all_frequent[index] = true;
                found = true;
            }
        }
        for (usz index = 0; index < MAX_ITEMSETS; index++) previous[index] = current[index];
        if (!found) break;
    }

    long rule_count = 0;
    for (long mask = 1; mask < mask_limit; mask++) {
        usz index = (usz)mask;
        if (!all_frequent[index] || item_count(mask) < 2) continue;
        for (long antecedent = (mask - 1) & mask; antecedent != 0; antecedent = (antecedent - 1) & mask) {
            long joint_support = supports[index];
            long antecedent_support = supports[(usz)antecedent];
            if (joint_support * SUPPORT_SCALE >= min_confidence_ppm * antecedent_support) rule_count++;
        }
    }
    return rule_count;
}
