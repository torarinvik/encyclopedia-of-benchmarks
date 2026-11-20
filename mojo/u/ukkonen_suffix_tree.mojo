from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_TEXT = 64
comptime MAX_SYMBOLS = MAX_TEXT + 1
comptime MAX_NODES = 2 * MAX_SYMBOLS
comptime MAX_INPUT_LENGTH = MAX_TEXT + 2

@fieldwise_init
struct UkkonenNode(Copyable):
    var start: Int
    var end: Int
    var suffix_link: Int
    var suffix_start: Int
    var open_end: Bool
    var children: InlineArray[Int, 5]

fn ukk_new_node(inout nodes: InlineArray[UkkonenNode, MAX_NODES],
                inout used: Int, start: Int, end: Int,
                open_end: Bool, suffix_start: Int) -> Int:
    if used >= MAX_NODES:
        return -1
    let node_id = used
    used += 1
    nodes[node_id] = UkkonenNode(start, end, 0, suffix_start, open_end,
                                 InlineArray[Int, 5](fill=-1))
    return node_id

fn ukk_edge_end(inout nodes: InlineArray[UkkonenNode, MAX_NODES],
                node_id: Int, current_end: Int) -> Int:
    if nodes[node_id].open_end:
        return current_end
    return nodes[node_id].end

fn ukk_append_token(token: Int64, inout position: Int64,
                    inout hash: Int64):
    hash += position * token
    position += 1

fn ukk_emit(inout nodes: InlineArray[UkkonenNode, MAX_NODES],
            inout text: InlineArray[Int, MAX_SYMBOLS], node_id: Int,
            current_end: Int, inout distinct: Int64,
            inout position: Int64, inout hash: Int64) -> Bool:
    for symbol in range(5):
        let child_id = nodes[node_id].children[symbol]
        if child_id < 0:
            continue
        let end = ukk_edge_end(inout nodes, child_id, current_end)
        let edge_length = end - nodes[child_id].start + 1
        if edge_length <= 0:
            return False

        ukk_append_token(1, inout position, inout hash)
        ukk_append_token(Int64(edge_length), inout position, inout hash)
        for offset in range(edge_length):
            let edge_symbol = text[nodes[child_id].start + offset]
            ukk_append_token(Int64(edge_symbol + 1), inout position, inout hash)
            if edge_symbol != 4:
                distinct += 1

        var has_children = False
        for next_symbol in range(5):
            if nodes[child_id].children[next_symbol] >= 0:
                has_children = True
                break
        if has_children:
            ukk_append_token(3, inout position, inout hash)
            if not ukk_emit(inout nodes, inout text, child_id, current_end,
                    inout distinct, inout position, inout hash):
                return False
            ukk_append_token(4, inout position, inout hash)
        else:
            if nodes[child_id].suffix_start < 0:
                return False
            ukk_append_token(2, inout position, inout hash)
            ukk_append_token(Int64(nodes[child_id].suffix_start + 1),
                inout position, inout hash)
    return True

@export("ukkonen_suffix_tree")
fn ukkonen_suffix_tree(input: UnsafePointer[Int64, ImmutAnyOrigin],
                       length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    if input[0] < 0 or input[0] > MAX_TEXT:
        return -1
    let text_length = Int(input[0])
    if length != c_size_t(text_length + 1):
        return -1

    var text = InlineArray[Int, MAX_SYMBOLS](fill=0)
    for index in range(text_length):
        let symbol = input[index + 1]
        if symbol < 0 or symbol > 3:
            return -1
        text[index] = Int(symbol)
    let total_length = text_length + 1
    text[text_length] = 4

    var nodes = InlineArray[UkkonenNode, MAX_NODES](fill=UkkonenNode(
        0, 0, 0, -1, False, InlineArray[Int, 5](fill=-1)))
    var used = 0
    let root = ukk_new_node(inout nodes, inout used, -1, -1, False, -1)
    if root != 0:
        return -1

    var active_node = root
    var active_edge = 0
    var active_length = 0
    var remaining = 0
    var leaf_end = -1
    for phase in range(total_length):
        leaf_end = phase
        remaining += 1
        var last_new_internal = -1
        while remaining > 0:
            if active_length == 0:
                active_edge = phase
            let edge_symbol = text[active_edge]
            let next_id = nodes[active_node].children[edge_symbol]
            if next_id < 0:
                let suffix_start = phase - remaining + 1
                let leaf = ukk_new_node(inout nodes, inout used, phase, -1,
                                        True, suffix_start)
                if leaf < 0:
                    return -1
                nodes[active_node].children[edge_symbol] = leaf
                if last_new_internal >= 0:
                    nodes[last_new_internal].suffix_link = active_node
                    last_new_internal = -1
            else:
                let next_end = ukk_edge_end(inout nodes, next_id, leaf_end)
                let edge_length = next_end - nodes[next_id].start + 1
                if active_length >= edge_length:
                    active_edge += edge_length
                    active_length -= edge_length
                    active_node = next_id
                    continue
                if text[nodes[next_id].start + active_length] == text[phase]:
                    if last_new_internal >= 0:
                        nodes[last_new_internal].suffix_link = active_node
                        last_new_internal = -1
                    active_length += 1
                    break

                let split_start = nodes[next_id].start
                let split_end = split_start + active_length - 1
                let split = ukk_new_node(inout nodes, inout used,
                    split_start, split_end, False, -1)
                if split < 0:
                    return -1
                nodes[active_node].children[edge_symbol] = split
                let suffix_start = phase - remaining + 1
                let leaf = ukk_new_node(inout nodes, inout used, phase, -1,
                                        True, suffix_start)
                if leaf < 0:
                    return -1
                nodes[split].children[text[phase]] = leaf
                nodes[next_id].start += active_length
                nodes[split].children[text[nodes[next_id].start]] = next_id
                if last_new_internal >= 0:
                    nodes[last_new_internal].suffix_link = split
                last_new_internal = split

            remaining -= 1
            if active_node == root and active_length > 0:
                active_length -= 1
                active_edge = phase - remaining + 1
            elif active_node != root:
                active_node = nodes[active_node].suffix_link

    var distinct: Int64 = 0
    var token_position: Int64 = 1
    var hash: Int64 = 0
    ukk_append_token(0, inout token_position, inout hash)
    if not ukk_emit(inout nodes, inout text, root, leaf_end,
            inout distinct, inout token_position, inout hash):
        return -1
    ukk_append_token(4, inout token_position, inout hash)
    if used > MAX_NODES or distinct > 2080 or hash > 2576350140:
        return -1
    return (Int64(used) << 44) | (distinct << 32) | hash
