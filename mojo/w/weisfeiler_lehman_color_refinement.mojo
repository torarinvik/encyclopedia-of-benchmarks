from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn bit_count(value: Int64) -> Int:
    var remaining = value
    var count = 0
    while remaining != 0:
        count += Int(remaining & 1)
        remaining >>= 1
    return count

fn weisfeiler_lehman_color_refinement(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 10:
        return -1

    var values = InlineArray[Int64, 10]()
    for index in range(Int(length)):
        values[index] = input[index]
    let n_value = values[0]
    if n_value < 0 or n_value > 8:
        return -1
    let n = Int(n_value)
    if length != c_size_t(1 + n):
        return -1

    var adjacency = InlineArray[Int64, 8]()
    var colors = InlineArray[Int64, 8]()
    var next_colors = InlineArray[Int64, 8]()
    let allowed = (1 << n) - 1
    var class_count = 0
    for vertex in range(n):
        let mask = values[1 + vertex]
        if mask < 0 or (mask & ~allowed) != 0 or (mask & (1 << vertex)) != 0:
            return -1
        adjacency[vertex] = mask
        colors[vertex] = Int64(bit_count(mask))
        var first_degree = True
        for prior in range(vertex):
            if colors[prior] == colors[vertex]:
                first_degree = False
            if ((adjacency[vertex] >> prior) & 1) != ((adjacency[prior] >> vertex) & 1):
                return -1
        if first_degree:
            class_count += 1
    if n == 0:
        return 0

    var stable = False
    while not stable:
        var keys = InlineArray[Int64, 8]()
        var unique_keys = InlineArray[Int64, 8]()
        var unique_count = 0
        for vertex in range(n):
            var neighbor_colors = InlineArray[Int64, 8]()
            var neighbor_count = 0
            for neighbor in range(n):
                if (adjacency[vertex] & (1 << neighbor)) == 0:
                    continue
                let value = colors[neighbor]
                var position = neighbor_count
                while position > 0 and neighbor_colors[position - 1] > value:
                    neighbor_colors[position] = neighbor_colors[position - 1]
                    position -= 1
                neighbor_colors[position] = value
                neighbor_count += 1

            var suffix: Int64 = 0
            for slot in range(8):
                suffix *= 9
                if slot < neighbor_count:
                    suffix += neighbor_colors[slot] + 1
            keys[vertex] = colors[vertex] * 43046721 + suffix

            var seen = False
            for prior in range(vertex):
                if keys[prior] == keys[vertex]:
                    seen = True
            if not seen:
                unique_keys[unique_count] = keys[vertex]
                unique_count += 1

        for index in range(1, unique_count):
            let value = unique_keys[index]
            var position = index
            while position > 0 and unique_keys[position - 1] > value:
                unique_keys[position] = unique_keys[position - 1]
                position -= 1
            unique_keys[position] = value

        for vertex in range(n):
            var rank = 0
            while unique_keys[rank] != keys[vertex]:
                rank += 1
            next_colors[vertex] = Int64(rank)
        if unique_count == class_count:
            stable = True
        class_count = unique_count
        for vertex in range(n):
            colors[vertex] = next_colors[vertex]

    var packed: Int64 = 0
    var place: Int64 = 1
    for vertex in range(n):
        packed += colors[vertex] * place
        place *= 9
    return packed
