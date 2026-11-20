from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const HB_GENERATIONS = 4
const HB_BUCKETS = 8
const HB_KEYS = 32
const HB_MAX_OPS = 64
const HB_MAX_WORDS = 194
const HB_MISS: Int64 = -2147483648

fn hb_find_in_table(heads: view[Int16], keys: view[Int16], links: view[Int16],
                    table: Int, key: Int) -> Int:
    var node = Int(heads[table * HB_BUCKETS + key % HB_BUCKETS])
    while node >= 0:
        let record = table * HB_KEYS + node
        if Int(keys[record]) == key: return node
        node = Int(links[record])
    return -1

fn hb_find(heads: view[Int16], keys: view[Int16], links: view[Int16],
           newest: Int, key: Int) -> Int:
    for age in range(HB_GENERATIONS):
        let table = (newest + age) % HB_GENERATIONS
        let node = hb_find_in_table(heads, keys, links, table, key)
        if node >= 0: return table * HB_KEYS + node
    return -1

fn hb_put(heads: mutable view[Int16], keys: mutable view[Int16],
          values: mutable view[Int16], links: mutable view[Int16],
          used: mutable view[Int16], newest: Int, key: Int, value: Int) -> None:
    let node = hb_find_in_table(heads, keys, links, newest, key)
    if node >= 0:
        values[newest * HB_KEYS + node] = Int16(value)
        return
    var fresh = 0
    while fresh < HB_KEYS and keys[newest * HB_KEYS + fresh] >= 0: fresh += 1
    if fresh >= HB_KEYS: return
    used[newest] = Int16(fresh + 1)
    let bucket = key % HB_BUCKETS
    let record = newest * HB_KEYS + fresh
    keys[record] = Int16(key)
    values[record] = Int16(value)
    links[record] = heads[newest * HB_BUCKETS + bucket]
    heads[newest * HB_BUCKETS + bucket] = Int16(fresh)

fn hb_remove(heads: mutable view[Int16], keys: mutable view[Int16],
             values: mutable view[Int16], links: mutable view[Int16], used: mutable view[Int16],
             table: Int, key: Int, target: Int) -> None:
    let bucket = key % HB_BUCKETS
    var previous = -1
    var node = Int(heads[table * HB_BUCKETS + bucket])
    while node >= 0 and node != target:
        previous = node
        node = Int(links[table * HB_KEYS + node])
    if node < 0: return
    let record = table * HB_KEYS + node
    if previous < 0:
        heads[table * HB_BUCKETS + bucket] = links[record]
    else:
        links[table * HB_KEYS + previous] = links[record]
    keys[record] = -1
    values[record] = 0
    links[record] = -1
    used[table] = Int16(Int(used[table]) - 1)

fn hb_write(output: mutable view[UInt8], word: Int, value: Int64) -> None:
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[word * 8 + byte] = UInt8((bits >> (byte * 8)) & 255)

fn hb_impl(input: view[Int64], output: mutable UInt8&, capacity: Int) -> Int64:
    let length = input.len()
    if length < 1 or length > HB_MAX_WORDS: return -1
    let count_value = input[0]
    if count_value < 0 or count_value > HB_MAX_OPS: return -1
    let count = Int(count_value)
    if length != 1 + 3 * count: return -1
    for op in range(count):
        let opcode = input[1 + 3 * op]
        let key = input[2 + 3 * op]
        let argument = input[3 + 3 * op]
        if opcode == 0:
            if key < 0 or key >= HB_KEYS or argument < -1000 or argument > 1000: return -1
        elif opcode == 1:
            if key < 0 or key >= HB_KEYS or argument != 0: return -1
        elif opcode == 2:
            if key != 0 or argument != 0: return -1
        else:
            return -1
    let required = count * 8
    if output.is_null() or capacity < required: return -2

    var heads = InlineArray[Int16, 32](fill=0)
    var keys = InlineArray[Int16, 128](fill=0)
    var values = InlineArray[Int16, 128](fill=0)
    var links = InlineArray[Int16, 128](fill=0)
    var used = InlineArray[Int16, 4](fill=0)
    var trace = InlineArray[Int64, 64](fill=0)
    for index in range(32): heads[index] = -1
    for index in range(128): keys[index] = -1
    var newest = 0
    for op in range(count):
        let opcode = Int(input[1 + 3 * op])
        let key = Int(input[2 + 3 * op])
        let argument = Int(input[3 + 3 * op])
        if opcode == 0:
            let found = hb_find(heads[0:32], keys[0:128], links[0:128], newest, key)
            trace[op] = 0 if found >= 0 else 1
            if found >= 0:
                let table = found // HB_KEYS
                let node = found % HB_KEYS
                if table != newest:
                    hb_remove(heads[0:32], keys[0:128], values[0:128], links[0:128], used[0:4], table, key, node)
            hb_put(heads[0:32], keys[0:128], values[0:128], links[0:128], used[0:4],
                   newest, key, argument)
        elif opcode == 1:
            let found = hb_find(heads[0:32], keys[0:128], links[0:128], newest, key)
            if found < 0:
                trace[op] = HB_MISS
            else:
                let table = found // HB_KEYS
                let node = found % HB_KEYS
                let value = Int(values[table * HB_KEYS + node])
                trace[op] = Int64(value)
                if table != newest:
                    hb_remove(heads[0:32], keys[0:128], values[0:128], links[0:128], used[0:4], table, key, node)
                    hb_put(heads[0:32], keys[0:128], values[0:128], links[0:128], used[0:4],
                           newest, key, value)
        else:
            let oldest = (newest + HB_GENERATIONS - 1) % HB_GENERATIONS
            trace[op] = Int64(used[oldest])
            for bucket in range(HB_BUCKETS): heads[oldest * HB_BUCKETS + bucket] = -1
            for slot in range(HB_KEYS): keys[oldest * HB_KEYS + slot] = -1
            used[oldest] = 0
            newest = oldest
    var result: mutable view[UInt8] = output[0:required]
    for op in range(count): hb_write(result, op, trace[op])
    return Int64(required)

@export("hashbelt_aging_hash_table")
fn hashbelt_aging_hash_table(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(HB_MAX_WORDS):
        return -1
    hb_impl(input[0:length], output, Int(capacity))
