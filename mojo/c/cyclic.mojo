from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cyclic")
fn cyclic(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 129: return -1
    let operations = input[0]
    if operations < 0 or operations > 64 or length != 1 + 2 * operations: return -1
    var values = InlineArray[Int64, 64](0)
    var next = InlineArray[Int64, 64](0)
    var previous = InlineArray[Int64, 64](0)
    var head: Int64 = -1
    var size: Int64 = 0
    var allocated: Int64 = 0
    var records = InlineArray[Int64, 5000](0)
    var record_count: Int64 = 0
    var query_count: Int64 = 0
    for op_index in range(operations):
        let op = input[1 + 2 * op_index]
        let arg = input[2 + 2 * op_index]
        if op < 0 or op > 5: return -1
        if op == 0:
            if arg < -2147483648 or arg > 2147483647 or allocated >= 64: return -1
            let node = allocated
            allocated += 1
            values[node] = arg
            if size == 0:
                head = node
                next[node] = node
                previous[node] = node
            else:
                let tail = previous[head]
                previous[node] = tail
                next[node] = head
                next[tail] = node
                previous[head] = node
            size += 1
        elif op == 1:
            if arg < -1000000 or arg > 1000000: return -1
            if size > 0:
                var places = arg % size
                if places < 0: places += size
                if places > size / 2:
                    places = size - places
                    for j in range(places): head = previous[head]
                else:
                    for j in range(places): head = next[head]
        elif op == 2:
            if arg != 0: return -1
            var deleted: Int64 = 0
            if size > 0:
                let node = head
                if size == 1: head = -1
                else:
                    let succ = next[node]
                    let pred = previous[node]
                    next[pred] = succ
                    previous[succ] = pred
                    head = succ
                values[node] = 0
                size -= 1
                deleted = 1
            records[record_count] = op_index; record_count += 1
            records[record_count] = op; record_count += 1
            records[record_count] = 1; record_count += 1
            records[record_count] = deleted; record_count += 1
            query_count += 1
        elif op == 3:
            if arg != 0: return -1
            records[record_count] = op_index; record_count += 1
            records[record_count] = op; record_count += 1
            records[record_count] = size; record_count += 1
            var cursor = head
            for j in range(size):
                records[record_count] = values[cursor]; record_count += 1
                cursor = next[cursor]
            query_count += 1
        elif op == 4:
            if arg < -1000000 or arg > 1000000 or size == 0: return -1
            while size > 1:
                var places = arg % size
                if places < 0: places += size
                if places > size / 2:
                    places = size - places
                    for j in range(places): head = previous[head]
                else:
                    for j in range(places): head = next[head]
                let node = head
                let succ = next[node]
                let pred = previous[node]
                next[pred] = succ
                previous[succ] = pred
                head = succ
                values[node] = 0
                size -= 1
                # Move one place backward as the source does after each removal.
                head = previous[head]
            let winner = values[head]
            while size > 0:
                let node = head
                if size == 1: head = -1
                else:
                    let succ = next[node]
                    let pred = previous[node]
                    next[pred] = succ
                    previous[succ] = pred
                    head = succ
                values[node] = 0
                size -= 1
            records[record_count] = op_index; record_count += 1
            records[record_count] = op; record_count += 1
            records[record_count] = 1; record_count += 1
            records[record_count] = winner; record_count += 1
            query_count += 1
        else:
            if arg != 0: return -1
            while size > 0:
                let node = head
                if size == 1: head = -1
                else:
                    let succ = next[node]
                    let pred = previous[node]
                    next[pred] = succ
                    previous[succ] = pred
                    head = succ
                values[node] = 0
                size -= 1
    let fields = 1 + record_count + 1 + size
    let bytes = fields * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < bytes: return -2
    var stage = InlineArray[Int64, 5000](0)
    var f: Int64 = 0
    stage[f] = query_count; f += 1
    for i in range(record_count): stage[f] = records[i]; f += 1
    stage[f] = size; f += 1
    var cursor = head
    for i in range(size):
        stage[f] = values[cursor]; f += 1
        cursor = next[cursor]
    for i in range(fields):
        let bits = UInt64(stage[i])
        for b in range(8): output[i * 8 + b] = UInt8((bits >> (8 * b)) & 255)
    return bytes
