module trie

// Fixed-capacity lowercase trie with set semantics and subtree word counts.
@[export: 'trie_benchmark']
pub fn trie_benchmark(values &i64, length usize) i64 {
    if length > 1024 { return -1 }
    mut children := [26624]int{init: 0}
    mut terminal := [1024]bool{init: false}
    mut subtree_words := [1024]int{init: 0}
    mut used_nodes := 1
    mut position := 0
    mut operation := 0
    mut checksum := i64(0)
    mut active_hash_sum := i64(0)

    for position < int(length) {
        if position + 1 >= int(length) { return -1 }
        opcode := unsafe { values[position] }
        word_length_value := unsafe { values[position + 1] }
        if opcode < 0 || opcode > 5 || word_length_value < 0 || word_length_value > 128 { return -1 }
        word_length := int(word_length_value)
        if opcode == 5 && word_length != 0 { return -1 }
        if word_length > int(length) - position - 2 { return -1 }

        mut word_hash := i64(word_length + 1)
        for i in 0 .. word_length {
            character := unsafe { values[position + 2 + i] }
            if character < 97 || character > 122 { return -1 }
            word_hash = (word_hash * 31 + character - 96) % 1000000007
        }

        mut node := 1
        mut observed := i64(0)
        if opcode == 0 {
            for i in 0 .. word_length {
                letter := int(unsafe { values[position + 2 + i] } - 97)
                edge := (node - 1) * 26 + letter
                mut child := children[edge]
                if child == 0 {
                    if used_nodes == 1024 { return -1 }
                    used_nodes++
                    child = used_nodes
                    children[edge] = child
                }
                node = child
            }
            if !terminal[node - 1] {
                terminal[node - 1] = true
                node = 1
                subtree_words[node - 1]++
                for i in 0 .. word_length {
                    letter := int(unsafe { values[position + 2 + i] } - 97)
                    node = children[(node - 1) * 26 + letter]
                    subtree_words[node - 1]++
                }
                active_hash_sum += word_hash
                observed = 1
            }
        } else {
            mut traversed := 0
            for traversed < word_length && node != 0 {
                letter := int(unsafe { values[position + 2 + traversed] } - 97)
                node = children[(node - 1) * 26 + letter]
                traversed++
            }
            if traversed != word_length { node = 0 }
            if opcode == 1 {
                if node != 0 && terminal[node - 1] {
                    terminal[node - 1] = false
                    node = 1
                    subtree_words[node - 1]--
                    for i in 0 .. word_length {
                        letter := int(unsafe { values[position + 2 + i] } - 97)
                        node = children[(node - 1) * 26 + letter]
                        subtree_words[node - 1]--
                    }
                    active_hash_sum -= word_hash
                    observed = 1
                }
            } else if opcode == 2 {
                if node != 0 && terminal[node - 1] { observed = 1 }
            } else if opcode == 3 {
                if node != 0 && subtree_words[node - 1] != 0 { observed = 1 }
            } else if opcode == 4 {
                if node != 0 { observed = i64(subtree_words[node - 1]) }
            } else {
                observed = i64(subtree_words[0])
            }
        }

        checksum += i64(operation + 1) * (observed + 1000000)
        operation++
        position += 2 + word_length
    }

    return checksum + i64(operation + 1) * (active_hash_sum + 1000000)
}
