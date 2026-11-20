// 64-ary hierarchical bitmap predecessor set.
package w_ary_predecessor_set

import "core:c"

Set :: struct {
    leaf: [4096]u64,
    group: [64]u64,
    top: u64,
}

low_bit :: proc "contextless" (bits: u64) -> int {
    low, high := 0, 64
    for high - low > 1 {
        middle := (low + high) / 2
        mask := (u64(1) << middle) - 1
        if bits & mask != 0 { high = middle } else { low = middle }
    }
    return low
}

high_bit :: proc "contextless" (bits: u64) -> int {
    low, high := 0, 64
    for high - low > 1 {
        middle := (low + high) / 2
        if bits >> middle != 0 { low = middle } else { high = middle }
    }
    return low
}

insert_key :: proc "contextless" (state: ^Set, key: int) -> i64 {
    word, bit_index := key >> 6, key & 63
    bit := u64(1) << bit_index
    old := state.leaf[word]
    if old & bit != 0 do return 0
    if old == 0 {
        group_index, slot := word >> 6, word & 63
        if state.group[group_index] == 0 do state.top |= u64(1) << group_index
        state.group[group_index] |= u64(1) << slot
    }
    state.leaf[word] = old | bit
    return 1
}

erase_key :: proc "contextless" (state: ^Set, key: int) -> i64 {
    word, bit_index := key >> 6, key & 63
    bit := u64(1) << bit_index
    old := state.leaf[word]
    if old & bit == 0 do return 0
    state.leaf[word] = old & ~bit
    if state.leaf[word] == 0 {
        group_index, slot := word >> 6, word & 63
        state.group[group_index] &= ~(u64(1) << slot)
        if state.group[group_index] == 0 do state.top &= ~(u64(1) << group_index)
    }
    return 1
}

successor :: proc "contextless" (state: ^Set, key: int) -> i64 {
    word, bit_index := key >> 6, key & 63
    candidates := state.leaf[word] >> bit_index
    if candidates != 0 do return i64(word * 64 + bit_index + low_bit(candidates) + 1)
    group_index, slot := word >> 6, word & 63
    later: u64 = 0
    if slot < 63 do later = state.group[group_index] >> (slot + 1)
    next_word: int
    if later != 0 {
        next_word = group_index * 64 + slot + 1 + low_bit(later)
    } else {
        if group_index < 63 do later = state.top >> (group_index + 1) else later = 0
        if later == 0 do return 0
        next_group := group_index + 1 + low_bit(later)
        next_word = next_group * 64 + low_bit(state.group[next_group])
    }
    return i64(next_word * 64 + low_bit(state.leaf[next_word]) + 1)
}

predecessor :: proc "contextless" (state: ^Set, key: int) -> i64 {
    word, bit_index := key >> 6, key & 63
    candidates := state.leaf[word] & ((u64(1) << bit_index) - 1)
    if candidates != 0 do return i64(word * 64 + high_bit(candidates) + 1)
    group_index, slot := word >> 6, word & 63
    earlier := state.group[group_index] & ((u64(1) << slot) - 1)
    previous_word: int
    if earlier != 0 {
        previous_word = group_index * 64 + high_bit(earlier)
    } else {
        earlier = state.top & ((u64(1) << group_index) - 1)
        if earlier == 0 do return 0
        previous_group := high_bit(earlier)
        previous_word = previous_group * 64 + high_bit(state.group[previous_group])
    }
    return i64(previous_word * 64 + high_bit(state.leaf[previous_word]) + 1)
}

@(export)
w_ary_predecessor_set :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 66 do return -1
    if input[0] < 0 || input[0] > 32 do return -1
    q := int(input[0])
    if int(length) != 1 + 2 * q do return -1
    state: Set = {}
    result: i64 = 0
    cursor := 1
    for operation := 0; operation < q; operation += 1 {
        opcode, raw_key := input[cursor], input[cursor + 1]
        cursor += 2
        if opcode < 0 || opcode > 4 || raw_key < 0 || raw_key >= 262144 do return -1
        key := int(raw_key)
        answer: i64
        if opcode == 0 {
            answer = insert_key(&state, key)
        } else if opcode == 1 {
            answer = erase_key(&state, key)
        } else if opcode == 2 {
            if state.leaf[key >> 6] & (u64(1) << (key & 63)) != 0 do answer = 1 else answer = 0
        } else if opcode == 3 {
            answer = successor(&state, key)
        } else {
            answer = predecessor(&state, key)
        }
        result += i64(operation + 1) * answer
    }
    return result
}
