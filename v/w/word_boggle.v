module word_boggle

const max_nodes = 481
const alphabet = 52

fn letter_index(ch i64) int {
    if ch >= 65 && ch <= 90 { return int(ch - 65) }
    if ch >= 97 && ch <= 122 { return int(ch - 97 + 26) }
    return -1
}

fn visit(board &i64, rows int, cols int, pos int, node int, mut children [max_nodes * alphabet]int, mut terminal [max_nodes]int, mut visited [36]bool, mut found [32]bool) {
    visited[pos] = true
    if terminal[node] >= 0 { found[terminal[node]] = true }
    row := pos / cols
    col := pos % cols
    for dr in -1 .. 2 {
        for dc in -1 .. 2 {
            if dr == 0 && dc == 0 { continue }
            nr := row + dr
            nc := col + dc
            if nr < 0 || nc < 0 || nr >= rows || nc >= cols { continue }
            next_pos := nr * cols + nc
            if visited[next_pos] { continue }
            child := children[node * alphabet + letter_index(unsafe { board[next_pos] })]
            if child >= 0 { visit(board, rows, cols, next_pos, child, mut children, mut terminal, mut visited, mut found) }
        }
    }
    visited[pos] = false
}

@[export: 'word_boggle']
fn word_boggle(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 4 || length > 551 { return -1 }
    unsafe {
        if input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 6 { return -1 }
        rows := int(input[0])
        cols := int(input[1])
        cells := rows * cols
        dict_at := 2 + cells
        if length <= usize(dict_at) || input[dict_at] < 0 || input[dict_at] > 32 { return -1 }
        count := int(input[dict_at])
        for i in 0 .. cells { if letter_index(input[2 + i]) < 0 { return -1 } }

        mut words := [480]i64{}
        mut lengths := [32]int{}
        mut unique := 0
        mut at := dict_at + 1
        for _ in 0 .. count {
            if at >= int(length) || input[at] < 1 || input[at] > 15 { return -1 }
            n := int(input[at]); at++
            if int(length) - at < n { return -1 }
            for j in 0 .. n { if letter_index(input[at + j]) < 0 { return -1 } }
            mut duplicate := false
            for w in 0 .. unique {
                if lengths[w] == n {
                    mut same := true
                    for j in 0 .. n { if words[w * 15 + j] != input[at + j] { same = false } }
                    if same { duplicate = true }
                }
            }
            if !duplicate {
                lengths[unique] = n
                for j in 0 .. n { words[unique * 15 + j] = input[at + j] }
                unique++
            }
            at += n
        }
        if at != int(length) { return -1 }

        mut children := [max_nodes * alphabet]int{init: -1}
        mut terminal := [max_nodes]int{init: -1}
        mut nodes := 1
        for w in 0 .. unique {
            mut node := 0
            for j in 0 .. lengths[w] {
                slot := node * alphabet + letter_index(words[w * 15 + j])
                if children[slot] < 0 { children[slot] = nodes; nodes++ }
                node = children[slot]
            }
            terminal[node] = w
        }
        mut found := [32]bool{}
        mut visited := [36]bool{}
        for p in 0 .. cells {
            child := children[letter_index(input[2 + p])]
            if child >= 0 { visit(input + 2, rows, cols, p, child, mut children, mut terminal, mut visited, mut found) }
        }

        mut order := [32]int{}
        mut found_count := 0
        mut output_size := 0
        for w in 0 .. unique { if found[w] { order[found_count] = w; found_count++; output_size += lengths[w] + 1 } }
        for i in 1 .. found_count {
            value := order[i]
            mut j := i
            for j > 0 {
                prev := order[j - 1]
                mut less := false
                mut decided := false
                limit := lengths[value]
                if lengths[prev] < limit { limit = lengths[prev] }
                for b in 0 .. limit {
                    if words[value * 15 + b] != words[prev * 15 + b] {
                        less = words[value * 15 + b] < words[prev * 15 + b]
                        decided = true
                        break
                    }
                }
                if !decided { less = lengths[value] < lengths[prev] }
                if !less { break }
                order[j] = prev
                j--
            }
            order[j] = value
        }
        if usize(output_size) > capacity { return -2 }
        if output_size > 0 && output == nil { return -2 }
        mut pos := 0
        for k in 0 .. found_count {
            w := order[k]
            for j in 0 .. lengths[w] { output[pos] = u8(words[w * 15 + j]); pos++ }
            output[pos] = 0
            pos++
        }
        return i64(output_size)
    }
}
