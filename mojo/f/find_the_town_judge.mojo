from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("find_the_town_judge")
fn find_the_town_judge(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 20002: return -2
    let people = values[0]
    let trust = values[1]
    if people < 1 or people > 1000 or trust < 0 or trust > 10000 or length != 2 + 2 * trust: return -2
    var incoming = InlineArray[Int64, 1001](0)
    var outgoing = InlineArray[Int64, 1001](0)
    for e in range(trust):
        let from = values[2 + 2 * e]
        let to = values[3 + 2 * e]
        if from < 1 or from > people or to < 1 or to > people or from == to: return -2
        outgoing[from] += 1
        incoming[to] += 1
    var judge: Int64 = -1
    for person in range(1, people + 1):
        if incoming[person] == people - 1 and outgoing[person] == 0:
            if judge != -1: return -1
            judge = person
    return judge
