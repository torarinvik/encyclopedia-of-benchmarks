"""Round-by-round adjacency-matrix reference for DSATUR coloring."""

INVALID_RESULT = -1
MAX_VERTICES = 12
MAX_EDGES = 66
MAX_PARSEABLE_INPUT_VALUES = 135


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_VALUES
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    vertex_count, edge_count = values[:2]
    if (not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES
            or len(values) != 2 + 2 * edge_count or len(values) > 134):
        return INVALID_RESULT

    adjacent = [[False] * vertex_count for _ in range(vertex_count)]
    for index in range(edge_count):
        first, second = values[2 + 2 * index:4 + 2 * index]
        if (not 0 <= first < second < vertex_count or adjacent[first][second]):
            return INVALID_RESULT
        adjacent[first][second] = adjacent[second][first] = True

    colors = [-1] * vertex_count
    for _ in range(vertex_count):
        selected = -1
        selected_saturation = -1
        selected_residual_degree = -1
        for vertex in range(vertex_count):
            if colors[vertex] >= 0:
                continue
            neighbor_colors = {colors[neighbor] for neighbor in range(vertex_count)
                               if adjacent[vertex][neighbor] and colors[neighbor] >= 0}
            residual_degree = sum(1 for neighbor in range(vertex_count)
                                  if adjacent[vertex][neighbor] and colors[neighbor] < 0)
            saturation = len(neighbor_colors)
            if (saturation > selected_saturation
                    or saturation == selected_saturation
                    and (residual_degree > selected_residual_degree
                         or residual_degree == selected_residual_degree
                         and (selected < 0 or vertex < selected))):
                selected = vertex
                selected_saturation = saturation
                selected_residual_degree = residual_degree

        forbidden = {colors[neighbor] for neighbor in range(vertex_count)
                     if adjacent[selected][neighbor] and colors[neighbor] >= 0}
        color = 0
        while color in forbidden:
            color += 1
        colors[selected] = color

    count = max(colors, default=-1) + 1
    packed = 0
    for vertex, color in enumerate(colors):
        packed |= color << (4 * vertex)
    return (count << 48) | packed
