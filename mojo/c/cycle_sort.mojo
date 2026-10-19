from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("cycle_sort")
fn cycle_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C"):
    if length < 2: return
    for cs in range(length - 1):
        var item = values[cs]
        var pos = cs
        for scan in range(cs + 1, length):
            if values[scan] < item: pos += 1
        if pos == cs: continue
        while pos < length and item == values[pos]: pos += 1
        if pos == length: continue
        var tmp = values[pos]
        values[pos] = item
        item = tmp
        while pos != cs:
            pos = cs
            for scan in range(cs + 1, length):
                if values[scan] < item: pos += 1
            while pos < length and item == values[pos]: pos += 1
            if pos == length: break
            tmp = values[pos]
            values[pos] = item
            item = tmp
