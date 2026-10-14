package trie

import "core:c"

// Fixed-capacity lowercase trie with set semantics and subtree word counts.
@(export)
trie_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 1024 do return -1
    children: [26624]c.size_t
    terminal: [1024]bool
    subtree_words: [1024]c.size_t
    used_nodes: c.size_t = 1
    position: c.size_t = 0
    operation: c.size_t = 0
    checksum: i64 = 0
    active_hash_sum: i64 = 0

    for position < length {
        if position + 1 >= length do return -1
        opcode := values[position]
        word_length_value := values[position + 1]
        if opcode < 0 || opcode > 5 || word_length_value < 0 || word_length_value > 128 do return -1
        word_length := c.size_t(word_length_value)
        if opcode == 5 && word_length != 0 do return -1
        if word_length > length - position - 2 do return -1

        word_hash: i64 = i64(word_length) + 1
        for i: c.size_t = 0; i < word_length; i += 1 {
            character := values[position + 2 + i]
            if character < 97 || character > 122 do return -1
            word_hash = (word_hash * 31 + character - 96) % 1000000007
        }

        node: c.size_t = 1
        observed: i64 = 0
        if opcode == 0 {
            for i: c.size_t = 0; i < word_length; i += 1 {
                letter := c.size_t(values[position + 2 + i] - 97)
                edge := (node - 1) * 26 + letter
                child := children[edge]
                if child == 0 {
                    if used_nodes == 1024 do return -1
                    used_nodes += 1
                    child = used_nodes
                    children[edge] = child
                }
                node = child
            }
            if !terminal[node - 1] {
                terminal[node - 1] = true
                node = 1
                subtree_words[node - 1] += 1
                for i: c.size_t = 0; i < word_length; i += 1 {
                    letter := c.size_t(values[position + 2 + i] - 97)
                    node = children[(node - 1) * 26 + letter]
                    subtree_words[node - 1] += 1
                }
                active_hash_sum += word_hash
                observed = 1
            }
        } else {
            traversed: c.size_t = 0
            for traversed < word_length && node != 0 {
                letter := c.size_t(values[position + 2 + traversed] - 97)
                node = children[(node - 1) * 26 + letter]
                traversed += 1
            }
            if traversed != word_length do node = 0
            if opcode == 1 {
                if node != 0 && terminal[node - 1] {
                    terminal[node - 1] = false
                    node = 1
                    subtree_words[node - 1] -= 1
                    for i: c.size_t = 0; i < word_length; i += 1 {
                        letter := c.size_t(values[position + 2 + i] - 97)
                        node = children[(node - 1) * 26 + letter]
                        subtree_words[node - 1] -= 1
                    }
                    active_hash_sum -= word_hash
                    observed = 1
                }
            } else if opcode == 2 {
                if node != 0 && terminal[node - 1] do observed = 1
            } else if opcode == 3 {
                if node != 0 && subtree_words[node - 1] != 0 do observed = 1
            } else if opcode == 4 {
                if node != 0 do observed = i64(subtree_words[node - 1])
            } else {
                observed = i64(subtree_words[0])
            }
        }

        checksum += i64(operation + 1) * (observed + 1000000)
        operation += 1
        position += 2 + word_length
    }

    return checksum + i64(operation + 1) * (active_hash_sum + 1000000)
}
