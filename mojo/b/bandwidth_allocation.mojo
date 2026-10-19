from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_USERS = 64

@export("bandwidth_allocation")
fn bandwidth_allocation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2:
        return -1
    let bandwidth = input[0]
    let count_value = input[1]
    if bandwidth < 0 or bandwidth > 100000 or count_value < 0 or count_value > MAX_USERS:
        return -1
    let count = Int(count_value)
    if length != c_size_t(2 + 2 * count):
        return -1
    var ratios = List[Float64](capacity=MAX_USERS)
    var order = List[Int](capacity=MAX_USERS)
    for index in range(count):
        let demand = input[2 + index]
        let value = input[2 + count + index]
        if demand < 1 or demand > 1000 or value < 0 or value > 10000:
            return -1
        ratios.append(Float64(value) / Float64(demand))
        order.append(index)
    for index in range(1, count):
        let key_ratio = ratios[index]
        let key_index = order[index]
        var position = index
        while position > 0 and ratios[position - 1] < key_ratio:
            ratios[position] = ratios[position - 1]
            order[position] = order[position - 1]
            position -= 1
        ratios[position] = key_ratio
        order[position] = key_index
    var remaining = bandwidth
    var total: Int64 = 0
    for position in range(count):
        let index = order[position]
        let demand = input[2 + index]
        let value = input[2 + count + index]
        if remaining >= demand:
            total += value
            remaining -= demand
        else:
            total += Int64(ratios[position] * Float64(remaining))
            break
    return total
