from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn merge_nodes(values: InlineArray[Int64, 128], inout links: InlineArray[Int, 128], left: Int, right: Int) -> Int:
    if left < 0: return right
    if right < 0: return left
    if values[left] <= values[right]:
        let following = links[left]
        links[left] = merge_nodes(values, links, following, right)
        return left
    let following = links[right]
    links[right] = merge_nodes(values, links, left, following)
    return right

fn sort_nodes(values: InlineArray[Int64, 128], inout links: InlineArray[Int, 128], head: Int) -> Int:
    if head < 0: return head
    if links[head] < 0: return head
    var slow = head
    var fast = links[head]
    while fast >= 0 and links[fast] >= 0:
        slow = links[slow]
        fast = links[links[fast]]
    let right_head = links[slow]
    links[slow] = -1
    let left = sort_nodes(values, links, head)
    let right = sort_nodes(values, links, right_head)
    return merge_nodes(values, links, left, right)

@export("merge_sort_linked_list")
fn merge_sort_linked_list(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                          output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 129:
        return -1
    if input[0] < 0 or input[0] > 128:
        return -1
    let count = Int(input[0])
    if Int(length) != count + 1:
        return -1
    var values = InlineArray[Int64, 128](fill=0)
    var links = InlineArray[Int, 128](fill=-1)
    for i in range(count):
        let value = input[i + 1]
        if value < -2147483648 or value > 2147483647:
            return -1
        for j in range(i):
            if values[j] == value:
                return -1
        values[i] = value
        if i + 1 < count:
            links[i] = i + 1
    var head = -1
    if count > 0:
        head = sort_nodes(values, links, 0)
    let byte_count = 4 * count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count):
        return -2
    var node = head
    for i in range(count):
        for byte in range(4):
            output[4 * i + byte] = UInt8((values[node] >> (8 * byte)) & 255)
        node = links[node]
    return Int64(byte_count)
