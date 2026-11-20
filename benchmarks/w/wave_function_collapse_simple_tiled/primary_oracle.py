"""Bitmask and FIFO-queue reference for the bounded simple-tiled WFC profile."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_CELLS = 16
MAX_TILES = 4
MAX_VALID_INPUT_LENGTH = 55
MAX_PARSEABLE_INPUT_LENGTH = 56
SUCCESS_FLAG = 1 << 32


def _decode(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None

    width, height, tile_count = values[:3]
    if not 1 <= width <= 4 or not 1 <= height <= 4 or not 1 <= tile_count <= MAX_TILES:
        return None
    cell_count = width * height
    if len(values) != 3 + 2 * cell_count + 5 * tile_count:
        return None
    full_mask = (1 << tile_count) - 1
    position = 3
    domains = values[position:position + cell_count]
    position += cell_count
    if any(not 1 <= domain <= full_mask for domain in domains):
        return None
    weights = values[position:position + tile_count]
    position += tile_count
    if any(not 1 <= weight <= 4 for weight in weights):
        return None
    compatibility = []
    for _direction in range(4):
        row = values[position:position + tile_count]
        if any(not 0 <= mask <= full_mask for mask in row):
            return None
        compatibility.append(row)
        position += tile_count
    draws = values[position:position + cell_count]
    if any(not 0 <= draw <= 65535 for draw in draws):
        return None

    for first in range(tile_count):
        for second in range(tile_count):
            north = bool(compatibility[0][first] & (1 << second))
            south_reverse = bool(compatibility[2][second] & (1 << first))
            east = bool(compatibility[1][first] & (1 << second))
            west_reverse = bool(compatibility[3][second] & (1 << first))
            if north != south_reverse or east != west_reverse:
                return None
    return width, height, tile_count, list(domains), list(weights), compatibility, list(draws)


def _neighbor(cell, width, height, direction):
    row, column = divmod(cell, width)
    if direction == 0 and row:
        return cell - width
    if direction == 1 and column + 1 < width:
        return cell + 1
    if direction == 2 and row + 1 < height:
        return cell + width
    if direction == 3 and column:
        return cell - 1
    return None


def _propagate(domains, compatibility, width, height, tile_count,
               start_cell=0, seed_all=False):
    cell_count = width * height
    queue = list(range(cell_count)) if seed_all else [start_cell]
    in_queue = [False] * cell_count
    for cell in queue:
        in_queue[cell] = True
    head = 0
    while head < len(queue):
        source = queue[head]
        head += 1
        in_queue[source] = False
        for direction in range(4):
            neighbor = _neighbor(source, width, height, direction)
            if neighbor is None:
                continue
            supported = 0
            for tile in range(tile_count):
                if domains[source] & (1 << tile):
                    supported |= compatibility[direction][tile]
            reduced = domains[neighbor] & supported
            if reduced == domains[neighbor]:
                continue
            domains[neighbor] = reduced
            if reduced == 0:
                return False
            if not in_queue[neighbor]:
                queue.append(neighbor)
                in_queue[neighbor] = True
    return True


def expected_result(values, input_is_null=False, input_length=None):
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    width, height, tile_count, domains, weights, compatibility, draws = decoded
    if not _propagate(domains, compatibility, width, height, tile_count, seed_all=True):
        return -2

    cell_count = width * height
    while True:
        best_cell = cell_count
        best_count = MAX_TILES + 1
        for cell, domain in enumerate(domains):
            count = domain.bit_count()
            if count > 1 and count < best_count:
                best_cell = cell
                best_count = count
        if best_cell == cell_count:
            break

        total_weight = sum(weights[tile] for tile in range(tile_count)
                           if domains[best_cell] & (1 << tile))
        rank = draws[best_cell] * total_weight // 65536
        selected = None
        for tile in range(tile_count):
            if not domains[best_cell] & (1 << tile):
                continue
            if rank < weights[tile]:
                selected = tile
                break
            rank -= weights[tile]
        if selected is None:
            return -2
        domains[best_cell] = 1 << selected
        if not _propagate(domains, compatibility, width, height, tile_count,
                          start_cell=best_cell):
            return -2

    result = SUCCESS_FLAG
    for cell, domain in enumerate(domains):
        tile = domain.bit_length() - 1
        result |= tile << (2 * cell)
    return result
