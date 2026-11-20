from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@extern("C")
fn calloc(count: c_size_t, size: c_size_t) -> UnsafePointer[Int64, MutAnyOrigin]

@extern("C")
fn free(memory: UnsafePointer[Int64, MutAnyOrigin]) -> None

fn insertion_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: Int) -> None:
    for index in range(1, length):
        let key = values[index]
        var position = index
        while position > 0 and values[position - 1] > key:
            values[position] = values[position - 1]
            position -= 1
        values[position] = key

@export("linear_probing_sort")
fn linear_probing_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C") -> None:
    if values == UnsafePointer[Int64, MutAnyOrigin]() or length < 2:
        return
    let count = Int(length)
    if count > 1024:
        insertion_sort(values, count)
        return

    var minimum = values[0]
    var maximum = values[0]
    for index in range(count):
        if values[index] < 0 or values[index] > 255:
            insertion_sort(values, count)
            return
        if values[index] < minimum:
            minimum = values[index]
        if values[index] > maximum:
            maximum = values[index]

    let main_slots = 256 * (count + 1) + 1
    let table_length = main_slots + count
    let table = calloc(c_size_t(table_length), c_size_t(8))
    if table == UnsafePointer[Int64, MutAnyOrigin]():
        insertion_sort(values, count)
        return

    let span = maximum - minimum
    for index in range(count):
        var home = 0
        if span != 0:
            home = Int((values[index] - minimum) * Int64(main_slots - 1) // span)
        var slot = home
        while table[slot] != 0:
            slot += 1
        table[slot] = values[index] + 1

    var output = 0
    for slot in range(table_length):
        if table[slot] != 0:
            values[output] = table[slot] - 1
            output += 1
    free(table)
