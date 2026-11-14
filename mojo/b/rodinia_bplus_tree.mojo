# Independent bounded Rodinia B+ tree point-search profile; see package LICENSE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("rodinia_bplus_tree")
fn rodinia_bplus_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 31: return -1
    if input[0] < 1 or input[0] > 3 or input[1] < 1 or input[1] > 3 or input[2] < 1 or input[2] > 16: return -1
    let left_count = Int(input[0]); let right_count = Int(input[1]); let queries = Int(input[2])
    if length != c_size_t(3+2*(left_count+right_count)+queries): return -1
    var keys = InlineArray[Int64, 6](fill=0)
    var values = InlineArray[Int64, 6](fill=0)
    var cursor = 3
    for leaf in range(2):
        var count = left_count
        if leaf == 1: count = right_count
        for slot in range(count):
            let key = input[cursor]; let value = input[cursor+1]; cursor += 2
            if key < -1000000 or key > 1000000 or value < 0 or value > 1000000: return -1
            if slot > 0 and key <= keys[leaf*3+slot-1]: return -1
            keys[leaf*3+slot] = key; values[leaf*3+slot] = value
    if keys[left_count-1] >= keys[3]: return -1
    var answer: Int64 = 0
    for query_index in range(queries):
        let query = input[cursor]; cursor += 1
        if query < -1000000 or query > 1000000: return -1
        var leaf = 0; var count = left_count
        if query >= keys[3]: leaf = 1; count = right_count
        for slot in range(count):
            if keys[leaf*3+slot] == query:
                answer += Int64(query_index+1)*(values[leaf*3+slot]+1)
                break
    return answer
