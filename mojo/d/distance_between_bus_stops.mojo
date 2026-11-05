from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin

@export("distance_between_bus_stops")
def distance_between_bus_stops(input: Optional[Pointer[Int64, ImmUntrackedOrigin]], length: c_size_t) abi("C") -> Int64:
    if input is None or length < 3 or length > 66:
        return -1
    var data = input.value()
    var stops = Int(length) - 2
    var start = data.unsafe_offset(0)[]
    var destination = data.unsafe_offset(1)[]
    if start < 0 or destination < 0 or start >= Int64(stops) or destination >= Int64(stops):
        return -1
    var low = Int(start if start < destination else destination)
    var high = Int(destination if start < destination else start)
    var total: Int64 = 0
    var direct: Int64 = 0
    for i in range(stops):
        var distance = data.unsafe_offset(i + 2)[]
        if distance < 0 or distance > 1000000:
            return -1
        total += distance
        if i >= low and i < high:
            direct += distance
    var other = total - direct
    return direct if direct < other else other
