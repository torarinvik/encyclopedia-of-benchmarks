from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_CELLS: Int = 16
comptime MAX_TILES: Int = 4
comptime MAX_PARSEABLE_INPUT_LENGTH: Int = 56

fn wfc_popcount_small(mask: UInt8) -> Int:
    var bits = mask
    var count = 0
    while bits != 0:
        bits = bits & (bits - 1)
        count += 1
    return count

fn wfc_propagate(
    domains: UnsafePointer[UInt8, MutAnyOrigin],
    compatibility: UnsafePointer[UInt8, MutAnyOrigin],
    width: Int,
    height: Int,
    tile_count: Int,
    start_cell: Int,
    seed_all: Bool,
) -> Bool:
    let cell_count = width * height
    var queue = InlineArray[Int, 16](fill=0)
    var in_queue = InlineArray[Bool, 16](fill=False)
    var head = 0
    var tail = 0
    var queued = 0
    if seed_all:
        for cell in range(cell_count):
            queue[tail] = cell
            tail = (tail + 1) % cell_count
            queued += 1
            in_queue[cell] = True
    else:
        queue[tail] = start_cell
        tail = (tail + 1) % cell_count
        queued += 1
        in_queue[start_cell] = True

    while queued != 0:
        let source = queue[head]
        head = (head + 1) % cell_count
        queued -= 1
        in_queue[source] = False
        let row = source / width
        let column = source % width
        for direction in range(4):
            var neighbor = 0
            var has_neighbor = False
            if direction == 0 and row != 0:
                neighbor = source - width
                has_neighbor = True
            elif direction == 1 and column + 1 < width:
                neighbor = source + 1
                has_neighbor = True
            elif direction == 2 and row + 1 < height:
                neighbor = source + width
                has_neighbor = True
            elif direction == 3 and column != 0:
                neighbor = source - 1
                has_neighbor = True
            if not has_neighbor:
                continue
            var supported: UInt8 = 0
            for tile in range(tile_count):
                let bit = UInt8(1) << UInt(tile)
                if (domains[source] & bit) != 0:
                    supported = supported | compatibility[direction * tile_count + tile]
            let reduced = domains[neighbor] & supported
            if reduced == domains[neighbor]:
                continue
            domains[neighbor] = reduced
            if reduced == 0:
                return False
            if not in_queue[neighbor]:
                queue[tail] = neighbor
                tail = (tail + 1) % cell_count
                queued += 1
                in_queue[neighbor] = True
    return True

@export("wave_function_collapse_simple_tiled")
fn wave_function_collapse_simple_tiled(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    input_length: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or input_length < 3 or input_length > MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    let width_value = input[0]
    let height_value = input[1]
    let tile_value = input[2]
    if width_value < 1 or width_value > 4 or height_value < 1 or height_value > 4 or tile_value < 1 or tile_value > 4:
        return -1
    let width = Int(width_value)
    let height = Int(height_value)
    let tile_count = Int(tile_value)
    let cell_count = width * height
    if input_length != c_size_t(3 + 2 * cell_count + 5 * tile_count):
        return -1
    let full_mask = UInt8((1 << tile_count) - 1)
    var domains = InlineArray[UInt8, 16](fill=0)
    var weights = InlineArray[UInt8, 4](fill=0)
    var compatibility = InlineArray[UInt8, 16](fill=0)
    var draws = InlineArray[UInt16, 16](fill=0)
    var position = 3
    for cell in range(cell_count):
        let value = input[position]
        if value < 1 or value > Int64(full_mask):
            return -1
        domains[cell] = UInt8(value)
        position += 1
    for tile in range(tile_count):
        let value = input[position]
        if value < 1 or value > 4:
            return -1
        weights[tile] = UInt8(value)
        position += 1
    for direction in range(4):
        for tile in range(tile_count):
            let value = input[position]
            if value < 0 or value > Int64(full_mask):
                return -1
            compatibility[direction * tile_count + tile] = UInt8(value)
            position += 1
    for cell in range(cell_count):
        let value = input[position]
        if value < 0 or value > 65535:
            return -1
        draws[cell] = UInt16(value)
        position += 1

    for first in range(tile_count):
        for second in range(tile_count):
            let north = (compatibility[first] & (UInt8(1) << UInt(second))) != 0
            let south_reverse = (compatibility[2 * tile_count + second] & (UInt8(1) << UInt(first))) != 0
            let east = (compatibility[tile_count + first] & (UInt8(1) << UInt(second))) != 0
            let west_reverse = (compatibility[3 * tile_count + second] & (UInt8(1) << UInt(first))) != 0
            if north != south_reverse or east != west_reverse:
                return -1

    if not wfc_propagate(domains.unsafe_ptr(), compatibility.unsafe_ptr(), width, height, tile_count, 0, True):
        return -2
    while True:
        var best_cell = cell_count
        var best_count = MAX_TILES + 1
        for cell in range(cell_count):
            let count = wfc_popcount_small(domains[cell])
            if count > 1 and count < best_count:
                best_cell = cell
                best_count = count
        if best_cell == cell_count:
            break
        var total_weight = 0
        for tile in range(tile_count):
            if (domains[best_cell] & (UInt8(1) << UInt(tile))) != 0:
                total_weight += Int(weights[tile])
        var rank = (Int(draws[best_cell]) * total_weight) / 65536
        var selected = tile_count
        for tile in range(tile_count):
            if (domains[best_cell] & (UInt8(1) << UInt(tile))) == 0:
                continue
            if rank < Int(weights[tile]):
                selected = tile
                break
            rank -= Int(weights[tile])
        if selected == tile_count:
            return -2
        domains[best_cell] = UInt8(1) << UInt(selected)
        if not wfc_propagate(domains.unsafe_ptr(), compatibility.unsafe_ptr(), width, height, tile_count, best_cell, False):
            return -2

    var result: Int64 = Int64(1) << 32
    for cell in range(cell_count):
        var tile = 0
        while (domains[cell] & (UInt8(1) << UInt(tile))) == 0:
            tile += 1
        result = result | (Int64(tile) << (2 * cell))
    return result
