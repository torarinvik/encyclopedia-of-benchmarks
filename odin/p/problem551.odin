package problem551

MAX_N :: i64(1_000_000_000_000_000)
STATE_CAPACITY :: 32_768
JUMP_CAPACITY :: 131_072
TABLE_MASK :: STATE_CAPACITY - 1

State :: struct { prefix_sum: i32, suffix: i64, head: i32 }
Jump :: struct { difference: i64, terms: i64, k: i32, next: i32 }
Pair :: struct { difference: i64, terms: i64 }
Memo :: struct { states: []State, jumps: []Jump, jump_count: int, failed: bool }

power10 :: proc(exponent: i64) -> i64 {
    value := i64(1)
    for _ in 0..<int(exponent) { value *= 10 }
    return value
}
digit_sum :: proc(value_input: i64) -> i64 {
    value := value_input
    total := i64(0)
    for value > 0 { total += value % 10; value /= 10 }
    return total
}
find_state :: proc(memo: ^Memo, prefix_sum, suffix: i64) -> int {
    slot := int((suffix % i64(STATE_CAPACITY) + prefix_sum * 1009) % i64(STATE_CAPACITY))
    for probe := 0; probe < STATE_CAPACITY; probe += 1 {
        index := (slot + probe) & TABLE_MASK
        state := &memo.states[index]
        if state.head == -2 {
            state.prefix_sum = i32(prefix_sum); state.suffix = suffix; state.head = -1
            return index
        }
        if i64(state.prefix_sum) == prefix_sum && state.suffix == suffix { return index }
    }
    memo.failed = true
    return -1
}
add_jump :: proc(memo: ^Memo, state_index: int, difference, terms, k: i64) {
    if memo.jump_count >= JUMP_CAPACITY { memo.failed = true; return }
    index := memo.jump_count
    memo.jump_count += 1
    memo.jumps[index] = Jump{difference, terms, i32(k), memo.states[state_index].head}
    memo.states[state_index].head = i32(index)
}
compute :: proc(value: ^i64, k, index_input, target: i64) -> Pair {
    index := index_input
    start := index
    base := power10(k)
    prefix_sum := digit_sum(value^ / base)
    suffix := value^ % base
    difference := i64(0)
    for index < target {
        index += 1
        addend := prefix_sum + digit_sum(suffix)
        difference += addend; suffix += addend
        if suffix >= base { break }
    }
    value^ += difference
    return Pair{difference, index - start}
}
next_term :: proc(value: ^i64, k, index, target: i64, memo: ^Memo) -> Pair {
    base := power10(k)
    prefix_sum := digit_sum(value^ / base)
    suffix := value^ % base
    max_terms := target - index
    state_index := find_state(memo, prefix_sum, suffix)
    if state_index < 0 { return Pair{0, 0} }
    difference, terms := i64(0), i64(0)
    best := -1
    for jump := memo.states[state_index].head; jump >= 0; jump = memo.jumps[jump].next {
        entry := memo.jumps[jump]
        if i64(entry.k) <= k && entry.terms <= max_terms && (best < 0 || entry.terms > memo.jumps[best].terms) { best = jump }
    }
    if best >= 0 { entry := memo.jumps[best]; difference = entry.difference; terms = entry.terms; value^ += difference }
    if terms >= max_terms || suffix + difference >= base { return Pair{difference, terms} }
    if k > 2 {
        for !memo.failed {
            extra := next_term(value, k-1, index+terms, target, memo)
            difference += extra.difference; terms += extra.terms
            if terms >= max_terms || suffix+difference >= base { break }
        }
    } else {
        extra := compute(value, k, index+terms, target)
        difference += extra.difference; terms += extra.terms
    }
    if !memo.failed && terms < max_terms { add_jump(memo, state_index, difference, terms, k) }
    return Pair{difference, terms}
}

@(export)
problem551 :: proc "c" (n: i64) -> i64 {
    if n < 1 || n > MAX_N do return -1
    memo := Memo{states = make([]State, STATE_CAPACITY), jumps = make([]Jump, JUMP_CAPACITY)}
    defer delete(memo.states); defer delete(memo.jumps)
    for i := 0; i < STATE_CAPACITY; i += 1 { memo.states[i].head = -2 }
    value, jumped := i64(1), i64(0)
    for jumped != n-1 && !memo.failed {
        step := next_term(&value, 18, 1+jumped, n, &memo)
        jumped += step.terms
    }
    if memo.failed do return -1
    return value
}
