const MAX_TRANSACTIONS: usize = 64;
const MAX_ITEMS: usize = 12;
const MAX_ITEMSETS: usize = 1 << MAX_ITEMS;
const SUPPORT_SCALE: i64 = 1_000_000;

fn itemCount(value: i64) u32 {
    var mask: u64 = @intCast(value);
    var count: u32 = 0;
    while (mask != 0) : (mask >>= 1) count += @intCast(mask & 1);
    return count;
}

fn supportIsFrequent(support: i64, transaction_count: i64, threshold_ppm: i64) bool {
    return support * SUPPORT_SCALE >= threshold_ppm * transaction_count;
}

export fn apriori(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 5) return -1;
    const values = input.?[0..length];
    const transaction_count = values[0];
    const items = values[1];
    const min_support_ppm = values[2];
    const min_confidence_ppm = values[3];
    if (transaction_count < 1 or transaction_count > MAX_TRANSACTIONS or items < 1 or items > MAX_ITEMS or
        min_support_ppm < 1 or min_support_ppm > SUPPORT_SCALE or min_confidence_ppm < 0 or
        min_confidence_ppm > SUPPORT_SCALE or length != 4 + @as(usize, @intCast(transaction_count))) return -1;

    const mask_limit: i64 = @as(i64, 1) << @intCast(items);
    var transactions: [MAX_TRANSACTIONS]i64 = @splat(0);
    for (0..@intCast(transaction_count)) |index| {
        if (values[index + 4] < 0 or values[index + 4] >= mask_limit) return -1;
        transactions[index] = values[index + 4];
    }
    var supports: [MAX_ITEMSETS]i64 = @splat(0);
    var previous: [MAX_ITEMSETS]bool = @splat(false);
    var all_frequent: [MAX_ITEMSETS]bool = @splat(false);
    var current: [MAX_ITEMSETS]bool = @splat(false);
    var mask: i64 = 1;
    while (mask < mask_limit) : (mask <<= 1) {
        var support: i64 = 0;
        for (0..@intCast(transaction_count)) |transaction| {
            if ((transactions[transaction] & mask) == mask) support += 1;
        }
        if (supportIsFrequent(support, transaction_count, min_support_ppm)) {
            supports[@intCast(mask)] = support;
            previous[@intCast(mask)] = true;
            all_frequent[@intCast(mask)] = true;
        }
    }

    for (2..@as(usize, @intCast(items)) + 1) |size| {
        @memset(&current, false);
        var found = false;
        for (1..@as(usize, @intCast(mask_limit))) |raw_candidate| {
            const candidate: i64 = @intCast(raw_candidate);
            if (itemCount(candidate) != size) continue;
            var all_subsets_frequent = true;
            for (0..@as(usize, @intCast(items))) |item| {
                const bit: i64 = @as(i64, 1) << @intCast(item);
                if ((candidate & bit) != 0 and !previous[@intCast(candidate ^ bit)]) {
                    all_subsets_frequent = false;
                    break;
                }
            }
            if (!all_subsets_frequent) continue;
            var support: i64 = 0;
            for (0..@intCast(transaction_count)) |transaction| {
                if ((transactions[transaction] & candidate) == candidate) support += 1;
            }
            if (supportIsFrequent(support, transaction_count, min_support_ppm)) {
                supports[@intCast(candidate)] = support;
                current[@intCast(candidate)] = true;
                all_frequent[@intCast(candidate)] = true;
                found = true;
            }
        }
        previous = current;
        if (!found) break;
    }

    var rule_count: i64 = 0;
    for (1..@as(usize, @intCast(mask_limit))) |raw_candidate| {
        const candidate: i64 = @intCast(raw_candidate);
        if (!all_frequent[@intCast(candidate)] or itemCount(candidate) < 2) continue;
        var antecedent = (candidate - 1) & candidate;
        while (antecedent != 0) : (antecedent = (antecedent - 1) & candidate) {
            if (supports[@intCast(candidate)] * SUPPORT_SCALE >= min_confidence_ppm * supports[@intCast(antecedent)])
                rule_count += 1;
        }
    }
    return rule_count;
}
