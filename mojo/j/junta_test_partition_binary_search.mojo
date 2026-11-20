from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn truth_at(table: InlineArray[UInt64, 4], point: UInt32) -> Int64:
    let word = Int(point / 64)
    let bit = Int(point % 64)
    return Int64((table[word] >> bit) & 1)

fn put_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

@export("junta_test_partition_binary_search")
fn junta_test_partition_binary_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 40: return -1
    let n64 = input[0]
    let groups64 = input[1]
    let words64 = input[2]
    if n64 < 1 or n64 > 8 or groups64 < 1 or groups64 > n64: return -1
    let n = Int(n64)
    let group_count = Int(groups64)
    let domain = 1 << n
    let truth_words = (domain + 63) // 64
    if words64 != Int64(truth_words): return -1
    let table_at = 3
    let labels_at = table_at + truth_words
    let tape_at = labels_at + n
    if length != c_size_t(tape_at + 24): return -1

    var truth = InlineArray[UInt64, 4](fill=0)
    for word in range(truth_words): truth[word] = bitcast[UInt64](input[table_at + word])
    let tail_bits = domain % 64
    if tail_bits != 0 and (truth[truth_words - 1] >> tail_bits) != 0: return -1

    var group_masks = InlineArray[UInt32, 8](fill=0)
    var groups_seen: UInt32 = 0
    for coordinate in range(n):
        let group = input[labels_at + coordinate]
        if group < 0 or group >= groups64: return -1
        group_masks[Int(group)] |= UInt32(1) << coordinate
        groups_seen |= UInt32(1) << Int(group)
    if groups_seen != (UInt32(1) << group_count) - 1: return -1
    let pair_limit = UInt64(1) << (2 * n)
    for round in range(24):
        let pair = input[tape_at + round]
        if pair < 0 or bitcast[UInt64](pair) >= pair_limit: return -1

    var result = InlineArray[Int64, 7](fill=0)
    var event_rounds = InlineArray[Int64, 2](fill=0)
    var event_groups = InlineArray[Int64, 2](fill=0)
    var found = 0
    var query_count = 0
    let all_coordinates = (UInt32(1) << n) - 1
    var active = all_coordinates
    for round in range(24):
        let packed = bitcast[UInt64](input[tape_at + round])
        let x = UInt32(packed & UInt64(all_coordinates))
        let y = UInt32((packed >> n) & UInt64(all_coordinates))
        let hybrid = (x & ~active) | (y & active)
        var left_value = truth_at(truth, x)
        let right_value = truth_at(truth, hybrid)
        query_count += 2
        if left_value != right_value:
            var candidates = InlineArray[UInt8, 8](fill=0)
            var candidate_count = 0
            for group in range(group_count):
                if (group_masks[group] & active) != 0:
                    candidates[candidate_count] = UInt8(group)
                    candidate_count += 1
            var left_endpoint = x
            var right_endpoint = hybrid
            while candidate_count > 1:
                let cut = candidate_count // 2
                var low_mask: UInt32 = 0
                for i in range(cut): low_mask |= group_masks[Int(candidates[i])]
                let probe = (left_endpoint & ~low_mask) | (right_endpoint & low_mask)
                let probe_value = truth_at(truth, probe)
                query_count += 1
                if probe_value != left_value:
                    right_endpoint = probe
                    candidate_count = cut
                else:
                    left_endpoint = probe
                    left_value = probe_value
                    for i in range(cut, candidate_count): candidates[i - cut] = candidates[i]
                    candidate_count -= cut
            let selected = Int(candidates[0])
            active &= ~group_masks[selected]
            event_rounds[found] = Int64(round)
            event_groups[found] = Int64(selected)
            found += 1
            if found > 1: break

    result[0] = if found > 1 then 1 else 0
    result[1] = Int64(found)
    result[2] = Int64(query_count)
    for i in range(found):
        result[3 + 2 * i] = event_rounds[i]
        result[4 + 2 * i] = event_groups[i]
    let result_words = 3 + 2 * found
    let result_bytes = result_words * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(result_bytes): return -2
    for i in range(result_words): put_i64(output, i * 8, result[i])
    return Int64(result_bytes)
