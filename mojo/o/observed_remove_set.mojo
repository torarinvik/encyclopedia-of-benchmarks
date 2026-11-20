from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

MAX_Q = 32
MAX_TAGS = 64
MAX_INPUT = 129

@export("observed_remove_set")
fn observed_remove_set(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT:
        return -1
    let q = input[0]
    if q < 0 or q > MAX_Q or length != c_size_t(1 + 4 * q):
        return -1
    for i in range(Int(q)):
        let op = input[1 + 4 * i]
        let replica = input[2 + 4 * i]
        let element = input[3 + 4 * i]
        let peer = input[4 + 4 * i]
        if op >= 0 and op <= 2:
            if replica < 0 or replica > 1 or element < 0 or element > 15 or peer != 0:
                return -1
        elif op == 3 or op == 4:
            if replica < 0 or replica > 1 or element != 0 or peer < 0 or peer > 1:
                return -1
        else:
            return -1

    var used = InlineArray[Bool, MAX_TAGS](fill=False)
    var tag_element = InlineArray[Int64, MAX_TAGS](fill=0)
    var next_sequence = InlineArray[Int, 2](fill=0)
    var additions = InlineArray[Bool, 2 * MAX_TAGS](fill=False)
    var removals = InlineArray[Bool, 2 * MAX_TAGS](fill=False)
    var answer: Int64 = 0
    var read_count = 0
    for i in range(Int(q)):
        let op = input[1 + 4 * i]
        let replica = Int(input[2 + 4 * i])
        let element = input[3 + 4 * i]
        let peer = Int(input[4 + 4 * i])
        let base = replica * MAX_TAGS
        let peer_base = peer * MAX_TAGS
        var result = False
        if op == 0:
            let tag = replica * MAX_Q + next_sequence[replica]
            next_sequence[replica] += 1
            used[tag] = True
            tag_element[tag] = element
            additions[base + tag] = True
        elif op == 1:
            for tag in range(MAX_TAGS):
                if additions[base + tag] and not removals[base + tag] and used[tag] and tag_element[tag] == element:
                    removals[base + tag] = True
        elif op == 2:
            for tag in range(MAX_TAGS):
                if additions[base + tag] and not removals[base + tag] and used[tag] and tag_element[tag] == element:
                    result = True
        elif op == 3:
            for tag in range(MAX_TAGS):
                additions[base + tag] = additions[base + tag] or additions[peer_base + tag]
                removals[base + tag] = removals[base + tag] or removals[peer_base + tag]
        else:
            result = True
            for tag in range(MAX_TAGS):
                if (additions[base + tag] and not additions[peer_base + tag]) or (removals[base + tag] and not removals[peer_base + tag]):
                    result = False
        if op == 2 or op == 4:
            if result:
                answer |= Int64(1) << read_count
            read_count += 1
    return answer
