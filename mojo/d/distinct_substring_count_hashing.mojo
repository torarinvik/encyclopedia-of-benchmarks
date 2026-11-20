from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_TEXT = 64
const HASH_MODULUS = 1_000_000_007

@export("distinct_substring_count_hashing")
fn distinct_substring_count_hashing(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 66:
        return -1
    let n_value = input[0]
    if n_value < 0 or n_value > MAX_TEXT or length != c_size_t(n_value + 1):
        return -1
    let n = Int(n_value)
    for i in range(n):
        if input[i + 1] < 0 or input[i + 1] > 255:
            return -1

    var prefix = InlineArray[Int64, 65](fill=0)
    var powers = InlineArray[Int64, 65](fill=0)
    powers[0] = 1
    for i in range(n):
        prefix[i + 1] = (prefix[i] * 257 + input[i + 1] + 1) % HASH_MODULUS
        powers[i + 1] = powers[i] * 257 % HASH_MODULUS

    var group_hash = InlineArray[Int64, 64](fill=-1)
    var group_head = InlineArray[Int64, 64](fill=-1)
    var representative_start = InlineArray[Int64, 64](fill=0)
    var representative_next = InlineArray[Int64, 64](fill=0)
    var distinct: Int64 = 0
    for width in range(1, n + 1):
        for slot in range(64):
            group_hash[slot] = -1
            group_head[slot] = -1
        var representative_count = 0
        for start in range(n - width + 1):
            let end = start + width
            var fingerprint = (prefix[end] - prefix[start] * powers[width] % HASH_MODULUS) % HASH_MODULUS
            if fingerprint < 0:
                fingerprint += HASH_MODULUS
            var slot = Int(fingerprint % 64)
            while group_hash[slot] != -1 and group_hash[slot] != fingerprint:
                slot = (slot + 1) % 64
            if group_hash[slot] == -1:
                group_hash[slot] = fingerprint

            var duplicate = False
            var prior = group_head[slot]
            while prior >= 0:
                let old_start = Int(representative_start[Int(prior)])
                var offset = 0
                while offset < width and input[start + offset + 1] == input[old_start + offset + 1]:
                    offset += 1
                if offset == width:
                    duplicate = True
                    break
                prior = representative_next[Int(prior)]
            if not duplicate:
                representative_start[representative_count] = Int64(start)
                representative_next[representative_count] = group_head[slot]
                group_head[slot] = Int64(representative_count)
                representative_count += 1
                distinct += 1
    return distinct
