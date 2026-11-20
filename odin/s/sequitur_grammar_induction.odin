// Clean-room bounded deterministic Sequitur grammar profile.
package sequitur_grammar_induction

import "core:c"

Grammar :: struct {
    symbols: [16384]int,
    lengths: [256]int,
    live: [256]bool,
    next_rule: int,
}
Duplicate :: struct { found: bool, r1,p1,r2,p2,left,right: int }

replace_pair :: proc(g: ^Grammar, rule, position, token: int) {
    for i := position+2; i < g.lengths[rule]; i += 1 { g.symbols[rule*64+i-1] = g.symbols[rule*64+i] }
    g.lengths[rule] -= 1
    g.symbols[rule*64+position] = token
}

find_duplicate :: proc(g: ^Grammar) -> Duplicate {
    for r1 := 0; r1 < g.next_rule; r1 += 1 {
        if g.live[r1] {
            for p1 := 0; p1+1 < g.lengths[r1]; p1 += 1 {
                left, right := g.symbols[r1*64+p1], g.symbols[r1*64+p1+1]
                for r2 := r1; r2 < g.next_rule; r2 += 1 {
                    if g.live[r2] {
                        start := 0
                        if r2 == r1 { start = p1+2 }
                        for p2 := start; p2+1 < g.lengths[r2]; p2 += 1 {
                            if g.symbols[r2*64+p2] == left && g.symbols[r2*64+p2+1] == right {
                                return Duplicate{true,r1,p1,r2,p2,left,right}
                            }
                        }
                    }
                }
            }
        }
    }
    return Duplicate{}
}

cleanup_one :: proc(g: ^Grammar) -> bool {
    for target := 1; target < g.next_rule; target += 1 {
        if g.live[target] {
            count, parent, position := 0, 0, 0
            token := 256+target
            for rule := 0; rule < g.next_rule; rule += 1 {
                if g.live[rule] {
                    for i := 0; i < g.lengths[rule]; i += 1 {
                        if g.symbols[rule*64+i] == token { count += 1; parent = rule; position = i }
                    }
                }
            }
            if count == 0 { g.live[target] = false; g.lengths[target] = 0; return true }
            if count == 1 {
                copy: [64]int
                replacement_length := g.lengths[target]
                for i := 0; i < replacement_length; i += 1 { copy[i] = g.symbols[target*64+i] }
                delta, old_length := replacement_length-1, g.lengths[parent]
                for i := old_length-1; i > position; i -= 1 { g.symbols[parent*64+i+delta] = g.symbols[parent*64+i] }
                for i := 0; i < replacement_length; i += 1 { g.symbols[parent*64+position+i] = copy[i] }
                g.lengths[parent] += delta
                g.live[target] = false; g.lengths[target] = 0
                return true
            }
        }
    }
    return false
}

normalize :: proc(g: ^Grammar) {
    for {
        for cleanup_one(g) {}
        d := find_duplicate(g)
        if !d.found { return }
        existing := -1
        for rule := 1; rule < g.next_rule; rule += 1 {
            if g.live[rule] && g.lengths[rule] == 2 && g.symbols[rule*64] == d.left && g.symbols[rule*64+1] == d.right { existing = rule; break }
        }
        if existing >= 0 {
            rule, position := d.r1, d.p1
            if rule == existing && position == 0 { rule, position = d.r2, d.p2 }
            replace_pair(g, rule, position, 256+existing)
        } else {
            fresh := g.next_rule
            g.next_rule += 1
            g.live[fresh] = true; g.lengths[fresh] = 2
            g.symbols[fresh*64] = d.left; g.symbols[fresh*64+1] = d.right
            replace_pair(g, d.r2, d.p2, 256+fresh)
            replace_pair(g, d.r1, d.p1, 256+fresh)
        }
    }
}

@(export)
sequitur_grammar_induction :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 66 { return -1 }
    if input[0] < 0 || input[0] > 64 || int(length) != int(input[0])+1 { return -1 }
    n := int(input[0])
    for i := 0; i < n; i += 1 { if input[i+1] < 0 || input[i+1] > 255 { return -1 } }
    g := Grammar{}
    g.live[0] = true; g.next_rule = 1
    for i := 0; i < n; i += 1 { g.symbols[g.lengths[0]] = int(input[i+1]); g.lengths[0] += 1; normalize(&g) }
    rules, symbols := i64(0), i64(0)
    for rule := 0; rule < g.next_rule; rule += 1 {
        if g.live[rule] { if rule != 0 { rules += 1 }; symbols += i64(g.lengths[rule]) }
    }
    return 1000*rules+symbols
}
