from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("activity_selection")
fn activity_selection(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or input[0] < 0 or input[0] > 64:
        return -1
    let count = Int(input[0])
    if length != c_size_t(1 + 2 * count):
        return -1
    if count == 0:
        return 0
    var starts = List[Int64](length=count, fill=0)
    var finishes = List[Int64](length=count, fill=0)
    for i in range(count):
        starts[i] = input[1 + 2 * i]
        finishes[i] = input[2 + 2 * i]
        if starts[i] > finishes[i]:
            return -1
    for i in range(1, count):
        let start = starts[i]
        let finish = finishes[i]
        var j = i
        while j > 0 and (finishes[j - 1] > finish or (finishes[j - 1] == finish and starts[j - 1] > start)):
            starts[j] = starts[j - 1]
            finishes[j] = finishes[j - 1]
            j -= 1
        starts[j] = start
        finishes[j] = finish
    var selected: Int64 = 1
    var last_finish = finishes[0]
    for i in range(1, count):
        if starts[i] >= last_finish:
            selected += 1
            last_finish = finishes[i]
    return selected
