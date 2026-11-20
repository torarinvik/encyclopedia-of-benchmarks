from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_TEXT = 24
comptime MAX_PATTERN = 32
comptime MAX_POSITIONS = 8
comptime MAX_NODES = 64
comptime POSITION_NODE = 1
comptime CONCAT_NODE = 2
comptime ALT_NODE = 3
comptime STAR_NODE = 4

@fieldwise_init
struct RegexNode(Copyable):
    var kind: Int
    var left: Int
    var right: Int
    var position: Int

@fieldwise_init
struct RegexParser:
    var pattern: InlineArray[Int64, MAX_PATTERN]
    var length: Int
    var cursor: Int
    var node_count: Int
    var position_count: Int
    var nodes: InlineArray[RegexNode, MAX_NODES]
    var symbols: InlineArray[UInt8, MAX_POSITIONS + 1]
    var failed: Bool

fn add_node(mut parser: RegexParser, kind: Int, left: Int, right: Int, position: Int) -> Int:
    if parser.node_count >= MAX_NODES:
        parser.failed = True
        return 0
    let result = parser.node_count
    parser.nodes[result] = RegexNode(kind=kind, left=left, right=right, position=position)
    parser.node_count += 1
    return result

fn parse_expression(mut parser: RegexParser) -> Int:
    var result = parse_concatenation(mut parser)
    while not parser.failed and parser.cursor < parser.length and parser.pattern[parser.cursor] == 124:
        parser.cursor += 1
        let right = parse_concatenation(mut parser)
        result = add_node(mut parser, ALT_NODE, result, right, 0)
    return result

fn parse_concatenation(mut parser: RegexParser) -> Int:
    if parser.cursor >= parser.length or parser.pattern[parser.cursor] == 124 or parser.pattern[parser.cursor] == 41:
        parser.failed = True
        return 0
    var result = parse_repetition(mut parser)
    while not parser.failed and parser.cursor < parser.length and parser.pattern[parser.cursor] != 124 and parser.pattern[parser.cursor] != 41:
        let right = parse_repetition(mut parser)
        result = add_node(mut parser, CONCAT_NODE, result, right, 0)
    return result

fn parse_repetition(mut parser: RegexParser) -> Int:
    var result = parse_atom(mut parser)
    if not parser.failed and parser.cursor < parser.length and parser.pattern[parser.cursor] == 42:
        parser.cursor += 1
        result = add_node(mut parser, STAR_NODE, result, 0, 0)
    return result

fn parse_atom(mut parser: RegexParser) -> Int:
    if parser.cursor >= parser.length:
        parser.failed = True
        return 0
    let token = parser.pattern[parser.cursor]
    parser.cursor += 1
    if token == 40:
        let result = parse_expression(mut parser)
        if parser.failed or parser.cursor >= parser.length or parser.pattern[parser.cursor] != 41:
            parser.failed = True
            return 0
        parser.cursor += 1
        return result
    if token != 97 and token != 98 and token != 99 and token != 46:
        parser.failed = True
        return 0
    if parser.position_count >= MAX_POSITIONS:
        parser.failed = True
        return 0
    parser.position_count += 1
    let position = parser.position_count
    parser.symbols[position] = UInt8(token)
    return add_node(mut parser, POSITION_NODE, 0, 0, position)

@export("glushkov_bit_parallel_regex_search")
fn glushkov_bit_parallel_regex_search(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 58: return -1
    if input[0] < 0 or input[0] > MAX_TEXT or input[1] < 1 or input[1] > MAX_PATTERN: return -1
    let text_length = Int(input[0])
    let pattern_length = Int(input[1])
    if Int(length) != 2 + text_length + pattern_length: return -1
    for i in range(text_length + pattern_length):
        if input[2 + i] < 1 or input[2 + i] > 127: return -1

    var parser = RegexParser(
        pattern=InlineArray[Int64, MAX_PATTERN](fill=0), length=pattern_length,
        cursor=0, node_count=0, position_count=0,
        nodes=InlineArray[RegexNode, MAX_NODES](fill=RegexNode(kind=0, left=0, right=0, position=0)),
        symbols=InlineArray[UInt8, MAX_POSITIONS + 1](fill=0), failed=False,
    )
    for i in range(pattern_length): parser.pattern[i] = input[2 + text_length + i]
    let root = parse_expression(mut parser)
    if parser.failed or parser.cursor != pattern_length or parser.node_count == 0: return -1

    var nullable = InlineArray[Bool, MAX_NODES](fill=False)
    var first = InlineArray[UInt16, MAX_NODES](fill=0)
    var last = InlineArray[UInt16, MAX_NODES](fill=0)
    var follow = InlineArray[UInt16, MAX_POSITIONS + 1](fill=0)
    for i in range(parser.node_count):
        let node = parser.nodes[i]
        if node.kind == POSITION_NODE:
            let bit = UInt16(1) << node.position
            first[i] = bit
            last[i] = bit
        elif node.kind == STAR_NODE:
            nullable[i] = True
            first[i] = first[node.left]
            last[i] = last[node.left]
            for pos in range(1, parser.position_count + 1):
                if (last[node.left] & (UInt16(1) << pos)) != 0: follow[pos] |= first[node.left]
        elif node.kind == ALT_NODE:
            nullable[i] = nullable[node.left] or nullable[node.right]
            first[i] = first[node.left] | first[node.right]
            last[i] = last[node.left] | last[node.right]
        else:
            nullable[i] = nullable[node.left] and nullable[node.right]
            first[i] = first[node.left] | (first[node.right] if nullable[node.left] else UInt16(0))
            last[i] = last[node.right] | (last[node.left] if nullable[node.right] else UInt16(0))
            for pos in range(1, parser.position_count + 1):
                if (last[node.left] & (UInt16(1) << pos)) != 0: follow[pos] |= first[node.right]
    follow[0] = first[root] | UInt16(1)

    var transitions = InlineArray[UInt16, 512](fill=0)
    let subset_count = 1 << (parser.position_count + 1)
    for subset in range(1, subset_count):
        var state = 0
        while ((subset >> state) & 1) == 0: state += 1
        transitions[subset] = transitions[subset & (subset - 1)] | follow[state]
    var byte_masks = InlineArray[UInt16, 128](fill=1)
    for pos in range(1, parser.position_count + 1):
        for byte in range(1, 128):
            if parser.symbols[pos] == 46 or Int(parser.symbols[pos]) == byte:
                byte_masks[byte] |= UInt16(1) << pos
    var staged = InlineArray[UInt8, MAX_TEXT](fill=0)
    var active = UInt16(1)
    for i in range(text_length):
        active = transitions[Int(active)] & byte_masks[Int(input[2 + i])]
        staged[i] = UInt8(1) if (active & last[root]) != 0 else UInt8(0)
    if text_length > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(text_length)): return -2
    for i in range(text_length): output[i] = staged[i]
    return Int64(text_length)
