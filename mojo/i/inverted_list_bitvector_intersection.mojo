from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("inverted_list_bitvector_intersection")
fn inverted_list_bitvector_intersection(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 258: return -1
    let domain_value = input[0]
    let list_count_value = input[1]
    if domain_value < 1 or domain_value > 1024 or list_count_value < 1 or list_count_value > 16:
        return -1

    let domain = Int(domain_value)
    let list_count = Int(list_count_value)
    let words_per_list = (domain + 63) // 64
    if Int(length) != 2 + list_count * words_per_list: return -1

    let remainder = domain % 64
    if remainder != 0:
        let valid_mask = (UInt64(1) << remainder) - UInt64(1)
        for list in range(list_count):
            let final_index = 2 + list * words_per_list + words_per_list - 1
            let final_word = bitcast[UInt64](input[final_index])
            if (final_word & ~valid_mask) != 0: return -1

    var intersection = InlineArray[UInt64, 16](fill=0)
    for word in range(words_per_list):
        var combined = ~UInt64(0)
        for list in range(list_count):
            let input_index = 2 + list * words_per_list + word
            combined &= bitcast[UInt64](input[input_index])
        intersection[word] = combined

    var results = InlineArray[Int64, 1024](fill=0)
    var result_count = 0
    for document_id in range(domain):
        let bit = UInt64(1) << (document_id % 64)
        if (intersection[document_id // 64] & bit) != 0:
            results[result_count] = Int64(document_id)
            result_count += 1

    let output_bytes = (result_count + 1) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    let count_bits = bitcast[UInt64](Int64(result_count))
    for byte in range(8):
        output[byte] = UInt8((count_bits >> (byte * 8)) & UInt64(255))
    for index in range(result_count):
        let bits = bitcast[UInt64](results[index])
        for byte in range(8):
            output[(index + 1) * 8 + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))
    return Int64(output_bytes)
