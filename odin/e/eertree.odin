package eertree

import "core:c"

Max_Text_Length :: 128
Max_Nodes :: Max_Text_Length + 2
Alphabet_Size :: 26

Node :: struct { length: int, suffix_link: int, next: [Alphabet_Size]int }
Tree :: struct { nodes: [Max_Nodes]Node }

initialize_node :: proc "contextless" (tree: ^Tree, id, node_length, suffix_link: int) {
    tree.nodes[id].length = node_length
    tree.nodes[id].suffix_link = suffix_link
    for letter := 0; letter < Alphabet_Size; letter += 1 {
        tree.nodes[id].next[letter] = -1
    }
}

find_extendable :: proc "contextless" (tree: ^Tree, text: []i64, position, start: int) -> int {
    node := start
    for {
        preceding := position - 1 - tree.nodes[node].length
        if preceding >= 0 && text[preceding] == text[position] do return node
        node = tree.nodes[node].suffix_link
    }
}

@(export)
eertree :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 1 || length > c.size_t(Max_Text_Length + 1) do return -1
    if values[0] < 0 || values[0] > i64(Max_Text_Length) do return -1
    text_length := int(values[0])
    if length != c.size_t(text_length + 1) do return -1
    var text_storage: [Max_Text_Length]i64
    for position := 0; position < text_length; position += 1 {
        value := values[position + 1]
        if value < 0 || value >= Alphabet_Size do return -1
        text_storage[position] = value
    }
    text := text_storage[:text_length]

    var tree: Tree
    initialize_node(&tree, 0, -1, 0)
    initialize_node(&tree, 1, 0, 0)
    node_count := 2
    longest_suffix := 1
    checksum := i64(0)
    for position := 0; position < text_length; position += 1 {
        letter := int(text[position])
        parent := find_extendable(&tree, text, position, longest_suffix)
        next := tree.nodes[parent].next[letter]
        if next < 0 {
            next = node_count
            node_count += 1
            initialize_node(&tree, next, tree.nodes[parent].length + 2, 0)
            tree.nodes[parent].next[letter] = next
            if tree.nodes[next].length == 1 {
                tree.nodes[next].suffix_link = 1
            } else {
                suffix_parent := find_extendable(&tree, text, position, tree.nodes[parent].suffix_link)
                suffix := tree.nodes[suffix_parent].next[letter]
                if suffix < 0 do return -1
                tree.nodes[next].suffix_link = suffix
            }
        }
        longest_suffix = next
        checksum += i64(position + 1) * i64(node_count - 2)
    }
    return checksum
}
