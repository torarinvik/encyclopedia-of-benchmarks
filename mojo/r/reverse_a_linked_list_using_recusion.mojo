from std.ffi import c_size_t
from std.memory import Pointer, stack_allocation

comptime MAX_N = 64
comptime MAX_INPUT_LENGTH = 65

def reverse_links(next_link: Pointer[Int32, UntrackedOrigin[mut=True]],
                  previous: Int, current: Int) -> Int:
    var following = next_link[unsafe_offset=current]
    var head = current
    if following >= 0:
        head = reverse_links(next_link, current, Int(following))
    next_link[unsafe_offset=current] = Int32(previous)
    next_link[unsafe_offset=previous] = -1
    return head

@export("reverse_a_linked_list_using_recusion")
def reverse_a_linked_list_using_recusion(input_address: UInt64, length: c_size_t,
                                       output_address: UInt64, capacity: c_size_t) abi("C") -> Int64:
    if input_address == 0 or length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    var input = Pointer[Int64, UntrackedOrigin[mut=False]](
        unsafe_from_address=Int(input_address))
    var raw_count = input[unsafe_offset=0]
    if raw_count < 2 or raw_count > MAX_N or length != c_size_t(raw_count + 1):
        return -1
    var count = Int(raw_count)
    for index in range(count):
        var value = input[unsafe_offset=index + 1]
        if value < -2147483648 or value > 2147483647:
            return -1
    var required = count * 4
    if output_address == 0 or capacity < c_size_t(required):
        return -2
    var output = Pointer[UInt8, UntrackedOrigin[mut=True]](
        unsafe_from_address=Int(output_address))
    var nodes = stack_allocation[MAX_N, Int32]()
    var next_link = stack_allocation[MAX_N, Int32]()
    for index in range(count):
        nodes[unsafe_offset=index] = Int32(input[unsafe_offset=index + 1])
        next_link[unsafe_offset=index] = Int32(index + 1) if index + 1 < count else Int32(-1)
    var node = reverse_links(next_link, 0, Int(next_link[unsafe_offset=0]))
    for index in range(count):
        var value = UInt32(nodes[unsafe_offset=node])
        for byte in range(4):
            output[unsafe_offset=index * 4 + byte] = UInt8(value)
            value >>= 8
        if index + 1 < count:
            node = Int(next_link[unsafe_offset=node])
    return Int64(required)
