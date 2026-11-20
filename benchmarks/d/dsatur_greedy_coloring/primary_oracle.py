"""Incremental saturation-set reference for DSATUR greedy coloring."""

INVALID_RESULT = -1
MAX_VERTICES = 12
MAX_EDGES = 66
MAX_INPUT_VALUES = 134
MAX_PARSEABLE_INPUT_VALUES = 135


def _graph(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_VALUES
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    vertex_count, edge_count = values[:2]
    if (not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES
            or len(values) != 2 + 2 * edge_count or len(values) > MAX_INPUT_VALUES):
        return None
    adjacency = [0] * vertex_count
    for index in range(edge_count):
        first, second = values[2 + 2 * index:4 + 2 * index]
        if (not 0 <= first < second < vertex_count
                or adjacency[first] & (1 << second)):
            return None
        adjacency[first] |= 1 << second
        adjacency[second] |= 1 << first
    return vertex_count, adjacency


def _pack(colors):
    color_count = max(colors, default=-1) + 1
    packed_colors = sum(color << (4 * vertex) for vertex, color in enumerate(colors))
    return (color_count << 48) | packed_colors


def expected_output(values, input_is_null=False, input_length=None):
    graph = _graph(values, input_is_null, input_length)
    if graph is None:
        return INVALID_RESULT
    vertex_count, adjacency = graph
    colors = [-1] * vertex_count
    saturation_colors = [0] * vertex_count
    residual_degree = [neighbors.bit_count() for neighbors in adjacency]

    for _ in range(vertex_count):
        selected = -1
        for vertex in range(vertex_count):
            if colors[vertex] >= 0:
                continue
            if (selected < 0
                    or (saturation_colors[vertex].bit_count(), residual_degree[vertex], -vertex)
                    > (saturation_colors[selected].bit_count(), residual_degree[selected], -selected)):
                selected = vertex

        used = saturation_colors[selected]
        color = 0
        while used & (1 << color):
            color += 1
        colors[selected] = color
        color_bit = 1 << color
        neighbors = adjacency[selected]
        while neighbors:
            bit = neighbors & -neighbors
            neighbor = bit.bit_length() - 1
            neighbors ^= bit
            if colors[neighbor] < 0:
                residual_degree[neighbor] -= 1
                saturation_colors[neighbor] |= color_bit
    return _pack(colors)
