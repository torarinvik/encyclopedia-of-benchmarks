package ternary_search_trie

import "core:c"

MAX_OPERATIONS :: 64
MAX_KEY_LENGTH :: 6
RECORD_WIDTH :: 9
MAX_INPUT_VALUES :: c.size_t(577)
MAX_PARSEABLE_INPUT_VALUES :: c.size_t(578)
MAX_NODES :: 384

Node :: struct {
    character: i64,
    left, middle, right: int,
    value: i64,
    present: bool,
}

put_node :: proc "contextless" (nodes: ^[MAX_NODES + 1]Node, node_id: int, key: ^i64,
    length, depth: int, value: i64, old_value: ^i64, size, node_count: ^int) -> int {
    current := node_id
    if current == 0 {
        node_count^ += 1
        current = node_count^
        nodes[current].character = key[depth]
    }
    if key[depth] < nodes[current].character {
        nodes[current].left = put_node(nodes, nodes[current].left, key, length,
            depth, value, old_value, size, node_count)
    } else if key[depth] > nodes[current].character {
        nodes[current].right = put_node(nodes, nodes[current].right, key, length,
            depth, value, old_value, size, node_count)
    } else if depth + 1 < length {
        nodes[current].middle = put_node(nodes, nodes[current].middle, key, length,
            depth + 1, value, old_value, size, node_count)
    } else {
        old_value^ = 0
        if nodes[current].present {
            old_value^ = nodes[current].value
        } else {
            size^ += 1
        }
        nodes[current].value = value
        nodes[current].present = true
    }
    return current
}

find_node :: proc "contextless" (nodes: ^[MAX_NODES + 1]Node, node_id: int, key: ^i64,
    length: int) -> int {
    current, depth := node_id, 0
    for current != 0 {
        if key[depth] < nodes[current].character {
            current = nodes[current].left
        } else if key[depth] > nodes[current].character {
            current = nodes[current].right
        } else if depth + 1 == length {
            return current
        } else {
            current = nodes[current].middle
            depth += 1
        }
    }
    return 0
}

delete_node :: proc "contextless" (nodes: ^[MAX_NODES + 1]Node, node_id: int, key: ^i64,
    length, depth: int, removed: ^i64, size: ^int) -> int {
    if node_id == 0 do return 0
    if key[depth] < nodes[node_id].character {
        nodes[node_id].left = delete_node(nodes, nodes[node_id].left, key, length,
            depth, removed, size)
    } else if key[depth] > nodes[node_id].character {
        nodes[node_id].right = delete_node(nodes, nodes[node_id].right, key, length,
            depth, removed, size)
    } else if depth + 1 < length {
        nodes[node_id].middle = delete_node(nodes, nodes[node_id].middle, key,
            length, depth + 1, removed, size)
    } else if nodes[node_id].present {
        removed^ = nodes[node_id].value
        nodes[node_id].value = 0
        nodes[node_id].present = false
        size^ -= 1
    }
    if !nodes[node_id].present && nodes[node_id].left == 0 &&
        nodes[node_id].middle == 0 && nodes[node_id].right == 0 {
        return 0
    }
    return node_id
}

count_nodes :: proc "contextless" (nodes: ^[MAX_NODES + 1]Node, node_id: int) -> int {
    if node_id == 0 do return 0
    present := 0
    if nodes[node_id].present do present = 1
    return present + count_nodes(nodes, nodes[node_id].left) +
        count_nodes(nodes, nodes[node_id].middle) + count_nodes(nodes, nodes[node_id].right)
}

count_matches :: proc "contextless" (nodes: ^[MAX_NODES + 1]Node, node_id: int, pattern: ^i64,
    length, depth: int) -> int {
    if node_id == 0 do return 0
    token := pattern[depth]
    if token == 46 {
        here := 0
        if depth + 1 == length {
            if nodes[node_id].present do here = 1
        } else {
            here = count_matches(nodes, nodes[node_id].middle, pattern, length, depth + 1)
        }
        return count_matches(nodes, nodes[node_id].left, pattern, length, depth) + here +
            count_matches(nodes, nodes[node_id].right, pattern, length, depth)
    }
    if token < nodes[node_id].character {
        return count_matches(nodes, nodes[node_id].left, pattern, length, depth)
    }
    if token > nodes[node_id].character {
        return count_matches(nodes, nodes[node_id].right, pattern, length, depth)
    }
    if depth + 1 == length {
        if nodes[node_id].present do return 1
        return 0
    }
    return count_matches(nodes, nodes[node_id].middle, pattern, length, depth + 1)
}

valid_input :: proc "contextless" (input: [^]i64, length: c.size_t,
    operation_count: ^int) -> bool {
    if input == nil || length < 1 || length > MAX_PARSEABLE_INPUT_VALUES do return false
    if input[0] < 0 || input[0] > MAX_OPERATIONS do return false
    operation_count^ = int(input[0])
    if length != c.size_t(1 + operation_count^ * RECORD_WIDTH) do return false
    for operation in 0..<operation_count^ {
        base := 1 + operation * RECORD_WIDTH
        opcode, key_length := input[base], input[base + 1]
        if opcode < 0 || opcode > 6 || key_length < 0 || key_length > MAX_KEY_LENGTH do return false
        if (opcode <= 2 && key_length == 0) || (opcode == 6 && key_length != 0) do return false
        for index in 0..<MAX_KEY_LENGTH {
            character := input[base + 2 + index]
            if index < int(key_length) {
                if !((character >= 97 && character <= 122) ||
                    (opcode == 5 && character == 46)) do return false
            } else if character != 0 do return false
        }
        value := input[base + RECORD_WIDTH - 1]
        if opcode == 0 {
            if value < 1 || value > 65535 do return false
        } else if value != 0 do return false
    }
    return true
}

@(export)
ternary_search_trie :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    operation_count: int
    if !valid_input(input, length, &operation_count) do return -1
    nodes: [MAX_NODES + 1]Node
    node_count, root, size := 0, 0, 0
    total: i64 = 0
    for operation in 0..<operation_count {
        base := 1 + operation * RECORD_WIDTH
        opcode, key_length := input[base], int(input[base + 1])
        key := &input[base + 2]
        value := input[base + RECORD_WIDTH - 1]
        observed: i64 = 0
        if opcode == 0 {
            root = put_node(&nodes, root, key, key_length, 0, value, &observed, &size, &node_count)
        } else if opcode == 1 {
            found := find_node(&nodes, root, key, key_length)
            if found != 0 && nodes[found].present do observed = nodes[found].value
        } else if opcode == 2 {
            root = delete_node(&nodes, root, key, key_length, 0, &observed, &size)
        } else if opcode == 3 {
            current, depth := root, 0
            for current != 0 && depth < key_length {
                if key[depth] < nodes[current].character {
                    current = nodes[current].left
                } else if key[depth] > nodes[current].character {
                    current = nodes[current].right
                } else {
                    depth += 1
                    if nodes[current].present do observed = i64(depth)
                    current = nodes[current].middle
                }
            }
        } else if opcode == 4 {
            if key_length == 0 {
                observed = i64(size)
            } else {
                found := find_node(&nodes, root, key, key_length)
                if found != 0 {
                    present := 0
                    if nodes[found].present do present = 1
                    observed = i64(present + count_nodes(&nodes, nodes[found].middle))
                }
            }
        } else if opcode == 5 && key_length != 0 {
            observed = i64(count_matches(&nodes, root, key, key_length, 0))
        } else if opcode == 6 {
            observed = i64(size)
        }
        total += i64(operation + 1) * observed
    }
    return total
}
