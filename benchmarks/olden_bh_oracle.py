"""Independent oracle for the bounded 3D Barnes--Hut field query."""

from __future__ import annotations

import math

MIN_BODIES = 2
MAX_BODIES = 16
MAX_INPUT_LENGTH = 6 + 4 * MAX_BODIES
OUTPUT_ELEMENTS = 4
INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_DEPTH = 16


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except (OverflowError, ValueError):
        return False


def expected_output(values: list[float] | None) -> tuple[int, list[float]]:
    """Return [potential, ax, ay, az] from an octree traversal."""
    if type(values) is not list or len(values) < 6:
        return INVALID_RESULT, []
    raw_count, theta, softening, qx, qy, qz = values[:6]
    if any(not _finite_number(value) for value in values):
        return INVALID_RESULT, []
    if type(raw_count) not in (int, float) or not float(raw_count).is_integer():
        return INVALID_RESULT, []
    count = int(raw_count)
    if not MIN_BODIES <= count <= MAX_BODIES or len(values) != 6 + 4 * count:
        return INVALID_RESULT, []
    if not 0.0 <= theta <= 2.0 or not 0.0 <= softening <= 1.0:
        return INVALID_RESULT, []
    query = (float(qx), float(qy), float(qz))
    bodies: list[tuple[tuple[float, float, float], float]] = []
    for body_index in range(count):
        record = values[6 + 4 * body_index:10 + 4 * body_index]
        if any(not float(value).is_integer() for value in record[:3]):
            return INVALID_RESULT, []
        position = tuple(float(value) for value in record[:3])
        mass = float(record[3])
        if any(not -32.0 <= coordinate <= 32.0 for coordinate in position):
            return INVALID_RESULT, []
        if not 1.0 <= mass <= 16.0:
            return INVALID_RESULT, []
        bodies.append((position, mass))
    positions = [body[0] for body in bodies]
    if len(set(positions)) != count or any(not -32.0 <= coordinate <= 32.0 for coordinate in query):
        return INVALID_RESULT, []
    if all(min(position[axis] for position in positions) <= query[axis]
           <= max(position[axis] for position in positions) for axis in range(3)):
        return INVALID_RESULT, []

    minima = tuple(min(position[axis] for position in positions) for axis in range(3))
    maxima = tuple(max(position[axis] for position in positions) for axis in range(3))
    side = max(maxima[axis] - minima[axis] for axis in range(3))
    center = tuple((minima[axis] + maxima[axis]) / 2.0 for axis in range(3))
    nodes: list[dict[str, object]] = [{"body": -1, "children": [-1] * 8}]

    def octant(position: tuple[float, float, float], point: tuple[float, float, float]) -> int:
        return int(position[0] >= point[0]) | (int(position[1] >= point[1]) << 1) | (int(position[2] >= point[2]) << 2)

    def child_center(point: tuple[float, float, float], half: float, child: int) -> tuple[float, float, float]:
        return tuple(point[axis] + (half / 2.0 if child & (1 << axis) else -half / 2.0) for axis in range(3))

    def insert(node_index: int, body_index: int, point: tuple[float, float, float], half: float, depth: int) -> None:
        node = nodes[node_index]
        old_body = int(node["body"])
        if old_body == -1:
            node["body"] = body_index
            return
        if depth >= MAX_DEPTH:
            raise ValueError("integer body coordinates did not separate before the tree depth bound")
        if old_body >= 0:
            node["body"] = -2
            children = node["children"]
            assert isinstance(children, list)
            for item in (old_body, body_index):
                item_position = bodies[item][0]
                child = octant(item_position, point)
                if children[child] == -1:
                    children[child] = len(nodes)
                    nodes.append({"body": -1, "children": [-1] * 8})
                insert(int(children[child]), item, child_center(point, half, child), half / 2.0, depth + 1)
            return
        children = node["children"]
        assert isinstance(children, list)
        child = octant(bodies[body_index][0], point)
        if children[child] == -1:
            children[child] = len(nodes)
            nodes.append({"body": -1, "children": [-1] * 8})
        insert(int(children[child]), body_index, child_center(point, half, child), half / 2.0, depth + 1)

    for body_index in range(count):
        insert(0, body_index, center, side / 2.0, 0)

    aggregate_mass = [0.0] * len(nodes)
    aggregate_center = [(0.0, 0.0, 0.0)] * len(nodes)

    def aggregate(node_index: int) -> tuple[float, tuple[float, float, float]]:
        node = nodes[node_index]
        body_index = int(node["body"])
        if body_index >= 0:
            mass = bodies[body_index][1]
            center_of_mass = bodies[body_index][0]
        else:
            children = node["children"]
            assert isinstance(children, list)
            mass = 0.0
            weighted = [0.0, 0.0, 0.0]
            for child in children:
                if child >= 0:
                    child_mass, child_center_of_mass = aggregate(int(child))
                    mass += child_mass
                    for axis in range(3):
                        weighted[axis] += child_mass * child_center_of_mass[axis]
            center_of_mass = tuple(weighted[axis] / mass for axis in range(3))
        aggregate_mass[node_index] = mass
        aggregate_center[node_index] = center_of_mass
        return mass, center_of_mass

    aggregate(0)
    potential = 0.0
    acceleration = [0.0, 0.0, 0.0]
    theta_sq = float(theta) * float(theta)
    eps_sq = float(softening) * float(softening)

    def interact(mass: float, position: tuple[float, float, float]) -> None:
        nonlocal potential
        displacement = tuple(position[axis] - query[axis] for axis in range(3))
        distance_sq = eps_sq
        for component in displacement:
            distance_sq += component * component
        distance = math.sqrt(distance_sq)
        contribution = mass / distance
        potential -= contribution
        scale = contribution / distance_sq
        for axis in range(3):
            acceleration[axis] += displacement[axis] * scale

    def walk(node_index: int, cell_side: float) -> None:
        node = nodes[node_index]
        body_index = int(node["body"])
        if body_index >= 0:
            interact(bodies[body_index][1], bodies[body_index][0])
            return
        distance_sq = 0.0
        for axis in range(3):
            displacement = aggregate_center[node_index][axis] - query[axis]
            distance_sq += displacement * displacement
        if theta_sq * distance_sq < cell_side * cell_side:
            children = node["children"]
            assert isinstance(children, list)
            for child in children:
                if child >= 0:
                    walk(int(child), cell_side / 2.0)
        else:
            interact(aggregate_mass[node_index], aggregate_center[node_index])

    walk(0, side)
    return OUTPUT_ELEMENTS, [potential, *acceleration]
