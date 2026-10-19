from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

fn apriori_popcount(value0: Int) -> Int:
    var value = value0
    var count = 0
    while value != 0:
        count += value & 1
        value >>= 1
    return count

@export("apriori")
fn apriori(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5:
        return -1
    let transaction_count = input[0]
    let items = input[1]
    let min_support = input[2]
    let min_confidence = input[3]
    if transaction_count < 1 or transaction_count > 64 or items < 1 or items > 12 or min_support < 1 or min_support > 1000000 or min_confidence < 0 or min_confidence > 1000000 or length != c_size_t(4 + transaction_count):
        return -1
    let mask_limit = 1 << Int(items)
    var transactions = List[Int](length=64, fill=0)
    for i in range(Int(transaction_count)):
        if input[4 + i] < 0 or input[4 + i] >= Int64(mask_limit):
            return -1
        transactions[i] = Int(input[4 + i])
    var supports = List[Int64](length=4096, fill=0)
    var previous = List[Int](length=4096, fill=0)
    var all_frequent = List[Int](length=4096, fill=0)
    var current = List[Int](length=4096, fill=0)
    for item in range(Int(items)):
        let mask = 1 << item
        var support: Int64 = 0
        for t in range(Int(transaction_count)):
            if (transactions[t] & mask) == mask:
                support += 1
        if support * 1000000 >= min_support * transaction_count:
            supports[mask] = support
            previous[mask] = 1
            all_frequent[mask] = 1
    for size in range(2, Int(items) + 1):
        for mask in range(mask_limit):
            current[mask] = 0
        var found = False
        for mask in range(1, mask_limit):
            if apriori_popcount(mask) != size:
                continue
            var all_subsets = True
            for item in range(Int(items)):
                let bit = 1 << item
                if (mask & bit) != 0 and previous[mask ^ bit] == 0:
                    all_subsets = False
                    break
            if not all_subsets:
                continue
            var support: Int64 = 0
            for t in range(Int(transaction_count)):
                if (transactions[t] & mask) == mask:
                    support += 1
            if support * 1000000 >= min_support * transaction_count:
                supports[mask] = support
                current[mask] = 1
                all_frequent[mask] = 1
                found = True
        for mask in range(mask_limit):
            previous[mask] = current[mask]
        if not found:
            break
    var rule_count: Int64 = 0
    for mask in range(1, mask_limit):
        if all_frequent[mask] == 0 or apriori_popcount(mask) < 2:
            continue
        var antecedent = (mask - 1) & mask
        while antecedent != 0:
            if supports[mask] * 1000000 >= min_confidence * supports[antecedent]:
                rule_count += 1
            antecedent = (antecedent - 1) & mask
    return rule_count
