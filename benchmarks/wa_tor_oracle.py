"""Deterministic bounded oracle for the pinned Wa-Tor simulation."""

from __future__ import annotations

from dataclasses import dataclass

MAX_WIDTH = 8
MAX_HEIGHT = 8
MAX_CHRONONS = 32
MAX_CELLS = MAX_WIDTH * MAX_HEIGHT
MAX_PARSEABLE_INPUT_LENGTH = 3 + 3 * MAX_CELLS + 1
INVALID_RESULT = -1
HASH_MODULUS = 2_147_483_647
HASH_MULTIPLIER = 1_000_003
PREY_REPRODUCTION_TIME = 5
PREDATOR_REPRODUCTION_TIME = 20
PREDATOR_INITIAL_ENERGY = 15
PREDATOR_FOOD_VALUE = 5
MAX_ENTITIES = 500

MOVE_DIRECTIONS = ((-1, 0), (0, 1), (1, 0), (0, -1))  # N, E, S, W
PREY_TARGET_DIRECTIONS = ((-1, 0), (1, 0), (0, -1), (0, 1))  # N, S, W, E


@dataclass
class Entity:
    kind: int
    row: int
    col: int
    timer: int
    energy: int
    alive: bool = True


def _move_and_reproduce(
    entities: list[Entity], board: list[int], entity_id: int, width: int, height: int
) -> None:
    entity = entities[entity_id]
    old_row, old_col = entity.row, entity.col
    moved = False
    for delta_row, delta_col in MOVE_DIRECTIONS:
        row = old_row + delta_row
        col = old_col + delta_col
        if 0 <= row < height and 0 <= col < width:
            destination = row * width + col
            if board[destination] == -1:
                board[old_row * width + old_col] = -1
                board[destination] = entity_id
                entity.row, entity.col = row, col
                moved = True
                break
    if moved and entity.timer <= 0:
        if sum(entity_id != -1 for entity_id in board) < MAX_ENTITIES:
            child_id = len(entities)
            breed_time = PREY_REPRODUCTION_TIME if entity.kind == 1 else PREDATOR_REPRODUCTION_TIME
            child_energy = 0 if entity.kind == 1 else PREDATOR_INITIAL_ENERGY
            entities.append(Entity(entity.kind, old_row, old_col, breed_time, child_energy))
            board[old_row * width + old_col] = child_id
            entity.timer = breed_time
    else:
        entity.timer -= 1


def _run(width: int, height: int, chronons: int, cells: list[tuple[int, int, int]]) -> int:
    board = [-1] * (width * height)
    entities: list[Entity] = []
    for cell_index, (kind, timer, energy) in enumerate(cells):
        if kind == 0:
            continue
        entity_id = len(entities)
        row, col = divmod(cell_index, width)
        entities.append(Entity(kind, row, col, timer, energy))
        board[cell_index] = entity_id

    for _ in range(chronons):
        # WaTor.get_entities() traverses rows and cells in row-major order.
        snapshot = [entity_id for entity_id in board if entity_id != -1]
        for entity_id in snapshot:
            entity = entities[entity_id]
            if not entity.alive:
                continue
            if entity.kind == 1:
                _move_and_reproduce(entities, board, entity_id, width, height)
                continue

            if entity.energy == 0:
                board[entity.row * width + entity.col] = -1
                entity.alive = False
                continue

            target_id = -1
            target_cell = -1
            for delta_row, delta_col in PREY_TARGET_DIRECTIONS:
                row = entity.row + delta_row
                col = entity.col + delta_col
                if 0 <= row < height and 0 <= col < width:
                    cell_index = row * width + col
                    occupant_id = board[cell_index]
                    if occupant_id != -1 and entities[occupant_id].kind == 1:
                        target_id, target_cell = occupant_id, cell_index
                        break

            if target_id != -1:
                prey = entities[target_id]
                prey.alive = False
                board[entity.row * width + entity.col] = -1
                board[target_cell] = entity_id
                entity.row, entity.col = divmod(target_cell, width)
                entity.energy += PREDATOR_FOOD_VALUE
            else:
                _move_and_reproduce(entities, board, entity_id, width, height)
            entity.energy -= 1

    prey_count = 0
    predator_count = 0
    state_hash = 0
    for entity_id in board:
        if entity_id == -1:
            code = 0
        else:
            entity = entities[entity_id]
            if entity.kind == 1:
                prey_count += 1
                code = entity.timer + 33
            else:
                predator_count += 1
                code = 1_000 + 53 * entity.energy + entity.timer + 32
        state_hash = (state_hash * HASH_MULTIPLIER + code) % HASH_MODULUS
    return state_hash * 4_225 + prey_count * 65 + predator_count


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
            or len(values) < 3):
        return INVALID_RESULT
    width, height, chronons = values[:3]
    if (not 1 <= width <= MAX_WIDTH or not 1 <= height <= MAX_HEIGHT
            or not 0 <= chronons <= MAX_CHRONONS):
        return INVALID_RESULT
    cell_count = width * height
    if len(values) != 3 + 3 * cell_count:
        return INVALID_RESULT

    cells: list[tuple[int, int, int]] = []
    for index in range(cell_count):
        kind, timer, energy = values[3 + 3 * index : 6 + 3 * index]
        if kind == 0:
            if timer != 0 or energy != 0:
                return INVALID_RESULT
        elif kind == 1:
            if not 0 <= timer <= PREY_REPRODUCTION_TIME or energy != 0:
                return INVALID_RESULT
        elif kind == 2:
            if not 0 <= timer <= PREDATOR_REPRODUCTION_TIME or not 0 <= energy <= PREDATOR_INITIAL_ENERGY:
                return INVALID_RESULT
        else:
            return INVALID_RESULT
        cells.append((kind, timer, energy))
    return _run(width, height, chronons, cells)
