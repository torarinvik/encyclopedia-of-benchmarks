from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("car_pool")
fn car_pool(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 194: return -1
    if input[0] < 0 or input[0] > 1000 or input[1] < 0 or input[1] > 64: return -1
    let capacity = input[0]
    let trip_count = input[1]
    if length != 2 + 3 * trip_count: return -1
    var events = InlineArray[Int64, 1001](0)
    for trip in range(trip_count):
        let offset = 2 + 3 * trip
        let passengers = input[offset]
        let origin = input[offset + 1]
        let destination = input[offset + 2]
        if passengers < 1 or passengers > 1000 or origin < 0 or origin >= destination or destination > 1000: return -1
        events[origin] += passengers
        events[destination] -= passengers
    var occupants: Int64 = 0
    for position in range(1000):
        occupants += events[position]
        if occupants > capacity: return 0
    return 1
