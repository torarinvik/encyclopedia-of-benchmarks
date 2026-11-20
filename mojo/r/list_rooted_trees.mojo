from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_VERTICES = 7
comptime MAX_SHAPES = 48
comptime MAX_WIDTH = 14
comptime MAX_CANDIDATES = 37
comptime SHAPE_POOL_SIZE = (MAX_VERTICES + 1) * MAX_SHAPES * MAX_WIDTH
comptime CANDIDATE_POOL_SIZE = MAX_CANDIDATES * MAX_WIDTH
comptime MAX_OUTPUT = 674

fn lrt_candidate_temp_less(
    inout candidate_text: InlineArray[UInt8, CANDIDATE_POOL_SIZE],
    candidate_index: Int, temp: InlineArray[UInt8, MAX_WIDTH]
) -> Bool:
    for byte in range(MAX_WIDTH):
        let prior = candidate_text[candidate_index * MAX_WIDTH + byte]
        if temp[byte] < prior: return True
        if temp[byte] > prior: return False
    return False

fn lrt_shape_temp_less(
    inout shapes: InlineArray[UInt8, SHAPE_POOL_SIZE],
    base: Int, prior_index: Int, temp: InlineArray[UInt8, MAX_WIDTH], width: Int
) -> Bool:
    let prior_base = base + prior_index * MAX_WIDTH
    for byte in range(width):
        if temp[byte] < shapes[prior_base + byte]: return True
        if temp[byte] > shapes[prior_base + byte]: return False
    return False

fn lrt_enumerate_multisets(
    inout shapes: InlineArray[UInt8, SHAPE_POOL_SIZE],
    inout counts: InlineArray[Int, MAX_VERTICES + 1],
    target: Int,
    inout candidate_sizes: InlineArray[Int, MAX_CANDIDATES],
    inout candidate_text: InlineArray[UInt8, CANDIDATE_POOL_SIZE],
    candidate_count: Int, start: Int, remaining: Int,
    inout children: InlineArray[UInt8, MAX_WIDTH], child_length: Int
):
    if remaining == 0:
        let shape_index = counts[target]
        let base = (target * MAX_SHAPES + shape_index) * MAX_WIDTH
        shapes[base] = UInt8(40)
        for byte in range(child_length):
            shapes[base + 1 + byte] = children[byte]
        shapes[base + child_length + 1] = UInt8(41)
        counts[target] = shape_index + 1
        return

    for index in range(start, candidate_count):
        let child_size = candidate_sizes[index]
        if child_size <= remaining:
            let encoded_length = 2 * child_size
            for byte in range(encoded_length):
                children[child_length + byte] = candidate_text[index * MAX_WIDTH + byte]
            lrt_enumerate_multisets(
                shapes, counts, target, candidate_sizes, candidate_text,
                candidate_count, index, remaining - child_size,
                children, child_length + encoded_length
            )

@export("list_rooted_trees")
fn list_rooted_trees(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != c_size_t(1):
        return -1
    if input[0] < 1 or input[0] > MAX_VERTICES:
        return -1
    let vertices = Int(input[0])

    var shapes = InlineArray[UInt8, SHAPE_POOL_SIZE]()
    var counts = InlineArray[Int, MAX_VERTICES + 1]()
    counts[1] = 1
    shapes[MAX_SHAPES * MAX_WIDTH] = UInt8(40)
    shapes[MAX_SHAPES * MAX_WIDTH + 1] = UInt8(41)

    for target in range(2, vertices + 1):
        var candidate_sizes = InlineArray[Int, MAX_CANDIDATES]()
        var candidate_text = InlineArray[UInt8, CANDIDATE_POOL_SIZE]()
        var candidate_count = 0
        for size in range(1, target):
            for shape_index in range(counts[size]):
                candidate_sizes[candidate_count] = size
                let shape_base = (size * MAX_SHAPES + shape_index) * MAX_WIDTH
                let candidate_base = candidate_count * MAX_WIDTH
                for byte in range(MAX_WIDTH):
                    candidate_text[candidate_base + byte] = shapes[shape_base + byte]
                candidate_count += 1

        for index in range(1, candidate_count):
            var temp = InlineArray[UInt8, MAX_WIDTH]()
            let source = index * MAX_WIDTH
            for byte in range(MAX_WIDTH):
                temp[byte] = candidate_text[source + byte]
            let saved_size = candidate_sizes[index]
            var place = index
            while place > 0 and lrt_candidate_temp_less(candidate_text, place - 1, temp):
                let previous = (place - 1) * MAX_WIDTH
                let destination = place * MAX_WIDTH
                for byte in range(MAX_WIDTH):
                    candidate_text[destination + byte] = candidate_text[previous + byte]
                candidate_sizes[place] = candidate_sizes[place - 1]
                place -= 1
            let destination = place * MAX_WIDTH
            for byte in range(MAX_WIDTH):
                candidate_text[destination + byte] = temp[byte]
            candidate_sizes[place] = saved_size

        var children = InlineArray[UInt8, MAX_WIDTH]()
        lrt_enumerate_multisets(
            shapes, counts, target, candidate_sizes, candidate_text,
            candidate_count, 0, target - 1, children, 0
        )

        let width = 2 * target
        let shape_pool_base = target * MAX_SHAPES * MAX_WIDTH
        for index in range(1, counts[target]):
            var temp = InlineArray[UInt8, MAX_WIDTH]()
            let source = shape_pool_base + index * MAX_WIDTH
            for byte in range(MAX_WIDTH):
                temp[byte] = shapes[source + byte]
            var place = index
            while place > 0 and lrt_shape_temp_less(shapes, shape_pool_base, place - 1, temp, width):
                let previous = shape_pool_base + (place - 1) * MAX_WIDTH
                let destination = shape_pool_base + place * MAX_WIDTH
                for byte in range(MAX_WIDTH):
                    shapes[destination + byte] = shapes[previous + byte]
                place -= 1
            let destination = shape_pool_base + place * MAX_WIDTH
            for byte in range(MAX_WIDTH):
                shapes[destination + byte] = temp[byte]

    let count = counts[vertices]
    let width = 2 * vertices
    let needed = 2 + count * width
    var staged = InlineArray[UInt8, MAX_OUTPUT]()
    staged[0] = UInt8(count & 255)
    staged[1] = UInt8((count >> 8) & 255)
    var position = 2
    let output_shapes = vertices * MAX_SHAPES * MAX_WIDTH
    for shape_index in range(count):
        let source = output_shapes + shape_index * MAX_WIDTH
        for byte in range(width):
            staged[position] = shapes[source + byte]
            position += 1

    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed):
        return -2
    for byte in range(needed):
        output[byte] = staged[byte]
    return Int64(needed)
