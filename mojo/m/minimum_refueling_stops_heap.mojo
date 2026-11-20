from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("minimum_refueling_stops_heap")
fn minimum_refueling_stops_heap(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 20: return -2
    let target = input[0]
    let start_fuel = input[1]
    let count_value = input[2]
    if target < 1 or target > 2000 or start_fuel < 0 or start_fuel > 2000 or count_value < 0 or count_value > 8: return -2
    let count = Int(count_value)
    if length != c_size_t(3 + 2 * count): return -2
    var previous: Int64 = 0
    for i in range(count):
        let position = input[3 + 2 * i]
        let fuel = input[4 + 2 * i]
        if position <= previous or position >= target or fuel < 1 or fuel > 2000: return -2
        previous = position

    var heap = InlineArray[Int64, 8](fill=0)
    var heap_length = 0
    var next_station = 0
    var reach = start_fuel
    var stops: Int64 = 0
    while reach < target:
        while next_station < count and input[3 + 2 * next_station] <= reach:
            var child = heap_length
            heap_length += 1
            heap[child] = input[4 + 2 * next_station]
            while child > 0:
                let parent = (child - 1) // 2
                if heap[parent] >= heap[child]: break
                let temporary = heap[parent]
                heap[parent] = heap[child]
                heap[child] = temporary
                child = parent
            next_station += 1
        if heap_length == 0: return -1
        let maximum = heap[0]
        heap_length -= 1
        if heap_length > 0:
            heap[0] = heap[heap_length]
            var parent = 0
            while True:
                let left = 2 * parent + 1
                let right = left + 1
                if left >= heap_length: break
                var child = left
                if right < heap_length and heap[right] > heap[left]: child = right
                if heap[parent] >= heap[child]: break
                let temporary = heap[parent]
                heap[parent] = heap[child]
                heap[child] = temporary
                parent = child
        reach += maximum
        stops += 1
    return stops
