from std.collections import List

fn shootout_hash_key(mut value: Int, base: Int, buckets: Int) -> Int:
    var digits = List[Int]()
    while True:
        let digit = value % base
        if digit < 10: digits.append(48 + digit)
        else: digits.append(97 + digit - 10)
        value //= base
        if value == 0: break
    var hash = Int64(0)
    for index in range(len(digits)):
        hash = 5 * hash + Int64(digits[len(digits) - 1 - index])
    return Int(hash % Int64(buckets))

fn shootout_hash_matches(mut hex_value: Int, mut decimal_value: Int) -> Bool:
    while hex_value != 0 and decimal_value != 0:
        let digit = hex_value % 16
        if digit >= 10 or digit != decimal_value % 10: return False
        hex_value //= 16
        decimal_value //= 10
    return hex_value == 0 and decimal_value == 0

@export("shootout_hash")
fn shootout_hash(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 3_500_000: return -1
    let bound = Int(n)
    var buckets = 53
    for prime in (53, 97, 193, 389, 769, 1543, 3079, 6151, 12289, 24593,
                  49157, 98317, 196613, 393241, 786433, 1572869, 3145739, 6291469):
        if prime >= bound:
            buckets = prime
            break
    var heads = List[Int](length=buckets, fill=0)
    var next = List[Int](length=bound + 1, fill=0)
    for value in range(1, bound + 1):
        let bucket = shootout_hash_key(value, 16, buckets)
        var node = heads[bucket]
        var previous = 0
        while node != 0:
            if node == value: break
            previous = node
            node = next[node]
        if node == 0:
            if previous == 0: heads[bucket] = value
            else: next[previous] = value
    var found = Int64(0)
    var value = bound
    while value > 0:
        let bucket = shootout_hash_key(value, 10, buckets)
        var node = heads[bucket]
        while node != 0:
            if shootout_hash_matches(node, value):
                found += 1
                break
            node = next[node]
        value -= 1
    return found
