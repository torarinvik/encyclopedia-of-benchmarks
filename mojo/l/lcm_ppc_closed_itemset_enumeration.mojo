from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias LCM_PPC_MAX_ITEMS = 8
alias LCM_PPC_MAX_ROWS = 16
alias LCM_PPC_MAX_WORDS = 513

fn lcm_ppc_support(input: UnsafePointer[Int64, ImmutAnyOrigin], row_count: Int,
        mask: Int64) -> Int:
    var count = 0
    for row in range(row_count):
        if (input[3 + row] & mask) == mask:
            count += 1
    return count

fn lcm_ppc_closure(input: UnsafePointer[Int64, ImmutAnyOrigin], row_count: Int,
        item_count: Int, mask: Int64) -> Int64:
    var common = (Int64(1) << item_count) - 1
    for row in range(row_count):
        let transaction = input[3 + row]
        if (transaction & mask) == mask:
            common &= transaction
    return common

fn lcm_ppc_core(input: UnsafePointer[Int64, ImmutAnyOrigin], row_count: Int,
        item_count: Int, mask: Int64, pattern_support: Int) -> Int:
    for item in range(item_count):
        let prefix_mask = (Int64(1) << (item + 1)) - 1
        if lcm_ppc_support(input, row_count, mask & prefix_mask) == pattern_support:
            return item
    return item_count - 1

fn lcm_ppc_put_i64(output: UnsafePointer[UInt8, MutAnyOrigin], word: Int,
        value: Int64) -> None:
    var bits = UInt64(value)
    for byte in range(8):
        output[word * 8 + byte] = UInt8(bits & 255)
        bits >>= 8

@export("lcm_ppc_closed_itemset_enumeration")
fn lcm_ppc_closed_itemset_enumeration(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 3 + LCM_PPC_MAX_ROWS:
        return -1
    let item_value = input[0]
    let row_value = input[1]
    let minimum = input[2]
    if item_value < 1 or item_value > LCM_PPC_MAX_ITEMS or row_value < 1 or
        row_value > LCM_PPC_MAX_ROWS or minimum < 1 or minimum > row_value or
        length != c_size_t(3 + row_value):
        return -1
    let item_count = Int(item_value)
    let row_count = Int(row_value)
    let limit = Int64(1) << item_count
    for row in range(row_count):
        let mask = input[3 + row]
        if mask < 0 or mask >= limit:
            return -1

    var words = InlineArray[Int64, LCM_PPC_MAX_WORDS](fill=0)
    var stack_mask = InlineArray[Int64, LCM_PPC_MAX_ITEMS + 1](fill=0)
    var stack_support = InlineArray[Int, LCM_PPC_MAX_ITEMS + 1](fill=0)
    var stack_core = InlineArray[Int, LCM_PPC_MAX_ITEMS + 1](fill=0)
    var next_item = InlineArray[Int, LCM_PPC_MAX_ITEMS + 1](fill=0)
    var entered = InlineArray[Bool, LCM_PPC_MAX_ITEMS + 1](fill=False)
    stack_mask[0] = lcm_ppc_closure(input, row_count, item_count, 0)
    stack_support[0] = row_count
    stack_core[0] = -1
    var depth = 0
    var record_count = 0
    var active = True
    while active:
        if not entered[depth]:
            words[1 + 2 * record_count] = stack_mask[depth]
            words[2 + 2 * record_count] = Int64(stack_support[depth])
            record_count += 1
            entered[depth] = True
            next_item[depth] = stack_core[depth] + 1
        if next_item[depth] >= item_count:
            entered[depth] = False
            if depth == 0:
                active = False
            else:
                depth -= 1
            continue

        let item = next_item[depth]
        next_item[depth] += 1
        let bit = Int64(1) << item
        let parent_mask = stack_mask[depth]
        if (parent_mask & bit) != 0:
            continue
        let extended = parent_mask | bit
        let child_support = lcm_ppc_support(input, row_count, extended)
        if child_support < Int(minimum):
            continue
        let child = lcm_ppc_closure(input, row_count, item_count, extended)
        let lower_prefix = bit - 1
        if (parent_mask & lower_prefix) != (child & lower_prefix):
            continue
        depth += 1
        stack_mask[depth] = child
        stack_support[depth] = child_support
        stack_core[depth] = lcm_ppc_core(input, row_count, item_count, child, child_support)
        entered[depth] = False

    words[0] = Int64(record_count)
    let output_bytes = 8 * (1 + 2 * record_count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    for word in range(1 + 2 * record_count):
        lcm_ppc_put_i64(output, word, words[word])
    return Int64(output_bytes)
