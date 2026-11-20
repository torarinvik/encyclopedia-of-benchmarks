package wave_function_collapse_simple_tiled

import "core:c"

MAX_CELLS :: 16
MAX_TILES :: 4
MAX_COMPATIBILITY :: 4 * MAX_TILES
MAX_PARSEABLE_INPUT_LENGTH :: 56

popcount_small :: proc "contextless" (mask: u8) -> int {
    bits := mask
    count := 0
    for bits != 0 {
        bits &= bits - 1
        count += 1
    }
    return count
}

propagate :: proc "contextless" (domains: [^]u8, compatibility: [^]u8,
                                 width, height, tile_count, start_cell: int,
                                 seed_all: bool) -> bool {
    cell_count := width * height
    queue: [MAX_CELLS]int = {}
    in_queue: [MAX_CELLS]bool = {}
    head, tail, queued := 0, 0, 0
    if seed_all {
        for cell := 0; cell < cell_count; cell += 1 {
            queue[tail] = cell
            tail = (tail + 1) % cell_count
            queued += 1
            in_queue[cell] = true
        }
    } else {
        queue[tail] = start_cell
        tail = (tail + 1) % cell_count
        queued += 1
        in_queue[start_cell] = true
    }
    for queued != 0 {
        source := queue[head]
        head = (head + 1) % cell_count
        queued -= 1
        in_queue[source] = false
        row, column := source / width, source % width
        for direction := 0; direction < 4; direction += 1 {
            neighbor := 0
            has_neighbor := false
            if direction == 0 && row != 0 { neighbor = source - width; has_neighbor = true }
            else if direction == 1 && column + 1 < width { neighbor = source + 1; has_neighbor = true }
            else if direction == 2 && row + 1 < height { neighbor = source + width; has_neighbor = true }
            else if direction == 3 && column != 0 { neighbor = source - 1; has_neighbor = true }
            if !has_neighbor do continue
            supported := u8(0)
            for tile := 0; tile < tile_count; tile += 1 {
                if domains[source] & (u8(1) << u32(tile)) != 0 {
                    supported |= compatibility[direction * tile_count + tile]
                }
            }
            reduced := domains[neighbor] & supported
            if reduced == domains[neighbor] do continue
            domains[neighbor] = reduced
            if reduced == 0 do return false
            if !in_queue[neighbor] {
                queue[tail] = neighbor
                tail = (tail + 1) % cell_count
                queued += 1
                in_queue[neighbor] = true
            }
        }
    }
    return true
}

@(export)
wave_function_collapse_simple_tiled :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
    if input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 4 || input[2] < 1 || input[2] > MAX_TILES do return -1
    width, height, tile_count := int(input[0]), int(input[1]), int(input[2])
    cell_count := width * height
    if length != c.size_t(3 + 2 * cell_count + 5 * tile_count) do return -1
    full_mask := u8((1 << tile_count) - 1)
    domains: [MAX_CELLS]u8 = {}
    weights: [MAX_TILES]u8 = {}
    compatibility: [MAX_COMPATIBILITY]u8 = {}
    draws: [MAX_CELLS]u16 = {}
    position := 3
    for cell := 0; cell < cell_count; cell += 1 {
        value := input[position]
        if value < 1 || value > i64(full_mask) do return -1
        domains[cell] = u8(value)
        position += 1
    }
    for tile := 0; tile < tile_count; tile += 1 {
        value := input[position]
        if value < 1 || value > 4 do return -1
        weights[tile] = u8(value)
        position += 1
    }
    for direction := 0; direction < 4; direction += 1 {
        for tile := 0; tile < tile_count; tile += 1 {
            value := input[position]
            if value < 0 || value > i64(full_mask) do return -1
            compatibility[direction * tile_count + tile] = u8(value)
            position += 1
        }
    }
    for cell := 0; cell < cell_count; cell += 1 {
        value := input[position]
        if value < 0 || value > 65535 do return -1
        draws[cell] = u16(value)
        position += 1
    }
    for first := 0; first < tile_count; first += 1 {
        for second := 0; second < tile_count; second += 1 {
            north := compatibility[first] & (u8(1) << u32(second)) != 0
            south_reverse := compatibility[2 * tile_count + second] & (u8(1) << u32(first)) != 0
            east := compatibility[tile_count + first] & (u8(1) << u32(second)) != 0
            west_reverse := compatibility[3 * tile_count + second] & (u8(1) << u32(first)) != 0
            if north != south_reverse || east != west_reverse do return -1
        }
    }
    if !propagate(&domains[0], &compatibility[0], width, height, tile_count, 0, true) do return -2
    for {
        best_cell := cell_count
        best_count := MAX_TILES + 1
        for cell := 0; cell < cell_count; cell += 1 {
            count := popcount_small(domains[cell])
            if count > 1 && count < best_count { best_cell = cell; best_count = count }
        }
        if best_cell == cell_count do break
        total_weight := 0
        for tile := 0; tile < tile_count; tile += 1 {
            if domains[best_cell] & (u8(1) << u32(tile)) != 0 do total_weight += int(weights[tile])
        }
        rank := int(draws[best_cell]) * total_weight / 65536
        selected := tile_count
        for tile := 0; tile < tile_count; tile += 1 {
            if domains[best_cell] & (u8(1) << u32(tile)) == 0 do continue
            if rank < int(weights[tile]) { selected = tile; break }
            rank -= int(weights[tile])
        }
        if selected == tile_count do return -2
        domains[best_cell] = u8(1) << u32(selected)
        if !propagate(&domains[0], &compatibility[0], width, height, tile_count, best_cell, false) do return -2
    }
    result := i64(1) << 32
    for cell := 0; cell < cell_count; cell += 1 {
        tile := 0
        for domains[cell] & (u8(1) << u32(tile)) == 0 do tile += 1
        result |= i64(tile) << u32(2 * cell)
    }
    return result
}
