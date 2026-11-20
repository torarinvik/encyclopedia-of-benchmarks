"""Set-domain reference using ordered full arc sweeps instead of a FIFO queue."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_PARSEABLE_INPUT_LENGTH = 56
SUCCESS_FLAG = 1 << 32


def _parse(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    width, height, tile_count = values[0], values[1], values[2]
    if width not in range(1, 5) or height not in range(1, 5) or tile_count not in range(1, 5):
        return None
    cell_count = width * height
    if len(values) != 3 + 2 * cell_count + 5 * tile_count:
        return None
    full_mask = (1 << tile_count) - 1
    cursor = 3
    domains = []
    for mask in values[cursor:cursor + cell_count]:
        if mask < 1 or mask > full_mask:
            return None
        domains.append({tile for tile in range(tile_count) if mask & (1 << tile)})
    cursor += cell_count
    weights = list(values[cursor:cursor + tile_count])
    if any(weight < 1 or weight > 4 for weight in weights):
        return None
    cursor += tile_count
    allowed = []
    for _ in range(4):
        masks = values[cursor:cursor + tile_count]
        if any(mask < 0 or mask > full_mask for mask in masks):
            return None
        allowed.append([
            {tile for tile in range(tile_count) if mask & (1 << tile)}
            for mask in masks
        ])
        cursor += tile_count
    draws = list(values[cursor:cursor + cell_count])
    if any(draw < 0 or draw > 65535 for draw in draws):
        return None
    for a in range(tile_count):
        for b in range(tile_count):
            if ((b in allowed[0][a]) != (a in allowed[2][b])
                    or (b in allowed[1][a]) != (a in allowed[3][b])):
                return None
    return width, height, tile_count, domains, weights, allowed, draws


def _neighbor(cell, width, height, direction):
    row, column = divmod(cell, width)
    if direction == 0 and row > 0:
        return cell - width
    if direction == 1 and column + 1 < width:
        return cell + 1
    if direction == 2 and row + 1 < height:
        return cell + width
    if direction == 3 and column > 0:
        return cell - 1
    return None


def _close_by_arc_sweeps(domains, allowed, width, height, tile_count):
    cell_count = width * height
    changed = True
    while changed:
        changed = False
        for source in range(cell_count):
            for direction in range(4):
                neighbor = _neighbor(source, width, height, direction)
                if neighbor is None:
                    continue
                supported = set()
                for source_tile in domains[source]:
                    supported.update(allowed[direction][source_tile])
                reduced = domains[neighbor] & supported
                if reduced == domains[neighbor]:
                    continue
                domains[neighbor] = reduced
                changed = True
                if not reduced:
                    return False
    return True


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    width, height, tile_count, domains, weights, allowed, draws = parsed
    if not _close_by_arc_sweeps(domains, allowed, width, height, tile_count):
        return -2
    cell_count = width * height
    while True:
        best_cell = cell_count
        best_count = tile_count + 1
        for cell, domain in enumerate(domains):
            count = len(domain)
            if count > 1 and count < best_count:
                best_cell = cell
                best_count = count
        if best_cell == cell_count:
            break
        total_weight = sum(weights[tile] for tile in domains[best_cell])
        rank = draws[best_cell] * total_weight // 65536
        selected = None
        for tile in range(tile_count):
            if tile not in domains[best_cell]:
                continue
            if rank < weights[tile]:
                selected = tile
                break
            rank -= weights[tile]
        if selected is None:
            return -2
        domains[best_cell] = {selected}
        if not _close_by_arc_sweeps(domains, allowed, width, height, tile_count):
            return -2

    result = SUCCESS_FLAG
    for cell, domain in enumerate(domains):
        result |= next(iter(domain)) << (2 * cell)
    return result
