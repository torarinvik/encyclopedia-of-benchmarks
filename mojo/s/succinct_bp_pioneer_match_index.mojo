from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_PAIRS = 32
alias MAX_BITS = 64
alias MAX_INPUT = 66
alias MAX_OUTPUT = 520
alias BLOCK_SIZE = 8
alias BLOCK_COUNT = 8
alias BASE_BITS = 16
alias MAX_LEVELS = 3
alias MISSING = 255

struct Index:
    var length: Int
    var bits: List[UInt8]
    var local_mate: List[UInt8]
    var depth: List[UInt8]
    var open_pioneers: List[UInt8]
    var close_pioneers: List[UInt8]
    var family: List[UInt8]
    var family_rank: List[UInt8]
    var group_source: List[UInt8]
    var group_target: List[UInt8]
    var group_depth: List[UInt8]
    var open_positions: List[UInt8]
    var open_groups: List[UInt8]
    var close_positions: List[UInt8]
    var close_groups: List[UInt8]

    fn __init__(out self):
        self.length = 0
        self.bits = List[UInt8](length=MAX_BITS, fill=UInt8(0))
        self.local_mate = List[UInt8](length=MAX_BITS, fill=UInt8(MISSING))
        self.depth = List[UInt8](length=MAX_BITS + 1, fill=UInt8(0))
        self.open_pioneers = List[UInt8]()
        self.close_pioneers = List[UInt8]()
        self.family = List[UInt8]()
        self.family_rank = List[UInt8](length=MAX_BITS, fill=UInt8(MISSING))
        self.group_source = List[UInt8]()
        self.group_target = List[UInt8]()
        self.group_depth = List[UInt8]()
        self.open_positions = List[UInt8]()
        self.open_groups = List[UInt8]()
        self.close_positions = List[UInt8]()
        self.close_groups = List[UInt8]()

fn ensure_group(inout index: Index, source: Int, target: Int, depth: Int) -> Int:
    for group in range(len(index.group_source)):
        if Int(index.group_source[group]) == source and Int(index.group_target[group]) == target and Int(index.group_depth[group]) == depth:
            return group
    let group = len(index.group_source)
    index.group_source.append(UInt8(source))
    index.group_target.append(UInt8(target))
    index.group_depth.append(UInt8(depth))
    return group

fn find_group(index: Index, source: Int, target: Int, depth: Int) -> Int:
    for group in range(len(index.group_source)):
        if Int(index.group_source[group]) == source and Int(index.group_target[group]) == target and Int(index.group_depth[group]) == depth:
            return group
    return -1

fn build(inout levels: List[Index], level: Int, bits: List[UInt8]) -> Bool:
    if level >= MAX_LEVELS or len(bits) > MAX_BITS:
        return False
    var index = levels[level]
    index.length = len(bits)
    var stack = List[UInt8]()
    var mates = List[UInt8](length=len(bits), fill=UInt8(0))
    for position in range(len(bits)):
        index.bits[position] = bits[position]
        index.local_mate[position] = UInt8(MISSING)
        index.family_rank[position] = UInt8(MISSING)
        if Int(bits[position]) == 1:
            index.depth[position + 1] = UInt8(Int(index.depth[position]) + 1)
            stack.append(UInt8(position))
        else:
            index.depth[position + 1] = UInt8(Int(index.depth[position]) - 1)
            let opening = Int(stack.pop())
            mates[opening] = UInt8(position)
            mates[position] = UInt8(opening)
    if len(bits) <= BASE_BITS:
        for position in range(len(bits)):
            index.local_mate[position] = mates[position]
        levels[level] = index
        return True

    var far = List[Bool](length=len(bits), fill=False)
    for position in range(len(bits)):
        if Int(mates[position]) // BLOCK_SIZE != position // BLOCK_SIZE:
            far[position] = True
        else:
            index.local_mate[position] = mates[position]

    var seen_open = List[Bool](length=BLOCK_COUNT, fill=False)
    var last_open_target = List[Int](length=BLOCK_COUNT, fill=0)
    for position in range(len(bits)):
        if Int(bits[position]) == 1 and far[position]:
            let block = position // BLOCK_SIZE
            let target = Int(mates[position]) // BLOCK_SIZE
            if not seen_open[block] or last_open_target[block] != target:
                index.open_pioneers.append(UInt8(position))
            seen_open[block] = True
            last_open_target[block] = target

    var seen_close = List[Bool](length=BLOCK_COUNT, fill=False)
    var last_close_target = List[Int](length=BLOCK_COUNT, fill=0)
    for step in range(len(bits)):
        let position = len(bits) - 1 - step
        if Int(bits[position]) == 0 and far[position]:
            let block = position // BLOCK_SIZE
            let target = Int(mates[position]) // BLOCK_SIZE
            if not seen_close[block] or last_close_target[block] != target:
                index.close_pioneers.append(UInt8(position))
            seen_close[block] = True
            last_close_target[block] = target

    var in_family = List[Bool](length=len(bits), fill=False)
    for i in range(len(index.open_pioneers)):
        let position = Int(index.open_pioneers[i])
        in_family[position] = True
        in_family[Int(mates[position])] = True
    for i in range(len(index.close_pioneers)):
        let position = Int(index.close_pioneers[i])
        in_family[position] = True
        in_family[Int(mates[position])] = True
    for position in range(len(bits)):
        if in_family[position]:
            index.family_rank[position] = UInt8(len(index.family))
            index.family.append(UInt8(position))

    for position in range(len(bits)):
        if not far[position]:
            continue
        let source = position // BLOCK_SIZE
        let target = Int(mates[position]) // BLOCK_SIZE
        var depth = Int(index.depth[position])
        if Int(bits[position]) == 0:
            depth = Int(index.depth[position + 1])
        let group = ensure_group(inout index, source, target, depth)
        if Int(bits[position]) == 1:
            index.open_positions.append(UInt8(position))
            index.open_groups.append(UInt8(group))
        else:
            index.close_positions.append(UInt8(position))
            index.close_groups.append(UInt8(group))

    levels[level] = index
    if len(index.family) == 0:
        return True
    var child_bits = List[UInt8](length=len(index.family), fill=UInt8(0))
    for rank in range(len(index.family)):
        child_bits[rank] = bits[Int(index.family[rank])]
    return build(inout levels, level + 1, child_bits)

fn rank_position(index: Index, group: Int, position: Int, openings: Bool) -> Int:
    var rank = 0
    if openings:
        for i in range(len(index.open_positions)):
            if Int(index.open_groups[i]) == group:
                if Int(index.open_positions[i]) == position:
                    return rank
                rank += 1
    else:
        for i in range(len(index.close_positions)):
            if Int(index.close_groups[i]) == group:
                if Int(index.close_positions[i]) == position:
                    return rank
                rank += 1
    return -1

fn select_position(index: Index, group: Int, rank: Int, openings: Bool) -> Int:
    var current = 0
    if openings:
        for i in range(len(index.open_positions)):
            if Int(index.open_groups[i]) == group:
                if current == rank:
                    return Int(index.open_positions[i])
                current += 1
    else:
        for i in range(len(index.close_positions)):
            if Int(index.close_groups[i]) == group:
                if current == rank:
                    return Int(index.close_positions[i])
                current += 1
    return -1

fn matching(levels: List[Index], level: Int, position: Int) -> Int:
    let index = levels[level]
    if Int(index.local_mate[position]) != MISSING:
        return Int(index.local_mate[position])
    let source = position // BLOCK_SIZE
    if Int(index.bits[position]) == 1:
        var pioneer = -1
        for i in range(len(index.open_pioneers)):
            let candidate = Int(index.open_pioneers[i])
            if candidate // BLOCK_SIZE == source and candidate <= position:
                pioneer = candidate
        if pioneer < 0:
            return -1
        let child_position = Int(index.family_rank[pioneer])
        let child_mate = matching(levels, level + 1, child_position)
        if child_mate < 0:
            return -1
        let anchor = Int(index.family[child_mate])
        let target = anchor // BLOCK_SIZE
        let depth = Int(index.depth[position])
        let group = find_group(index, source, target, depth)
        let opposite = find_group(index, target, source, depth)
        if group < 0 or opposite < 0:
            return -1
        let rank = rank_position(index, group, position, True)
        if rank < 0:
            return -1
        return select_position(index, opposite, rank, False)

    var pioneer = -1
    for i in range(len(index.close_pioneers)):
        let candidate = Int(index.close_pioneers[i])
        if candidate // BLOCK_SIZE == source and candidate >= position:
            if pioneer < 0 or candidate < pioneer:
                pioneer = candidate
    if pioneer < 0:
        return -1
    let child_position = Int(index.family_rank[pioneer])
    let child_mate = matching(levels, level + 1, child_position)
    if child_mate < 0:
        return -1
    let anchor = Int(index.family[child_mate])
    let target = anchor // BLOCK_SIZE
    let depth = Int(index.depth[position + 1])
    let group = find_group(index, source, target, depth)
    let opposite = find_group(index, target, source, depth)
    if group < 0 or opposite < 0:
        return -1
    let rank = rank_position(index, group, position, False)
    if rank < 0:
        return -1
    return select_position(index, opposite, rank, True)

fn put_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & 255)

@export("succinct_bp_pioneer_match_index")
fn succinct_bp_pioneer_match_index(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT:
        return -1
    let pairs = input[0]
    if pairs < 1 or pairs > MAX_PAIRS or Int(length) != 1 + 2 * Int(pairs):
        return -1
    let bit_count = 2 * Int(pairs)
    var bits = List[UInt8](length=bit_count, fill=UInt8(0))
    var balance = 0
    for position in range(bit_count):
        let bit = input[position + 1]
        if bit != 0 and bit != 1:
            return -1
        bits[position] = UInt8(bit)
        if bit == 1:
            balance += 1
        else:
            balance -= 1
        if balance < 0:
            return -1
    if balance != 0:
        return -1
    let required = Int(length) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required) or required > MAX_OUTPUT:
        return -2

    var levels = List[Index]()
    for _ in range(MAX_LEVELS):
        levels.append(Index())
    if not build(inout levels, 0, bits):
        return -1
    var answers = List[Int](length=bit_count, fill=0)
    for position in range(bit_count):
        answers[position] = matching(levels, 0, position)
        if answers[position] < 0:
            return -1
    put_i64(output, 0, Int64(bit_count))
    for position in range(bit_count):
        put_i64(output, 8 * (position + 1), Int64(answers[position]))
    return Int64(required)
