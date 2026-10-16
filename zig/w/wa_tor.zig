const MAX_WIDTH: usize = 8;
const MAX_HEIGHT: usize = 8;
const MAX_CELLS: usize = 64;
const MAX_CHRONONS: usize = 32;
const MAX_ENTITY_RECORDS: usize = MAX_CELLS * (MAX_CHRONONS + 1);
const HASH_MODULUS: i64 = 2_147_483_647;
const HASH_MULTIPLIER: i64 = 1_000_003;

const Entity = struct {
    kind: i32,
    row: usize,
    col: usize,
    timer: i32,
    energy: i32,
    alive: bool,
};

fn breedTime(kind: i32) i32 {
    return if (kind == 1) 5 else 20;
}

fn moveAndReproduce(entities: []Entity, entity_count: *usize, board: []i32,
                    entity_id: usize, width: usize, height: usize) void {
    const old_row = entities[entity_id].row;
    const old_col = entities[entity_id].col;
    const delta_rows = [_]i32{-1, 0, 1, 0}; // N, E, S, W
    const delta_cols = [_]i32{0, 1, 0, -1};
    var moved = false;
    for (0..4) |direction| {
        const row = @as(i32, @intCast(old_row)) + delta_rows[direction];
        const col = @as(i32, @intCast(old_col)) + delta_cols[direction];
        if (row < 0 or row >= @as(i32, @intCast(height)) or col < 0 or col >= @as(i32, @intCast(width))) continue;
        const destination = @as(usize, @intCast(row)) * width + @as(usize, @intCast(col));
        if (board[destination] != -1) continue;
        board[old_row * width + old_col] = -1;
        board[destination] = @intCast(entity_id);
        entities[entity_id].row = @intCast(row);
        entities[entity_id].col = @intCast(col);
        moved = true;
        break;
    }
    if (moved and entities[entity_id].timer <= 0) {
        if (entity_count.* < MAX_ENTITY_RECORDS) {
            const child_id = entity_count.*;
            const kind = entities[entity_id].kind;
            const timer = breedTime(kind);
            entities[child_id] = .{
                .kind = kind,
                .row = old_row,
                .col = old_col,
                .timer = timer,
                .energy = if (kind == 1) 0 else 15,
                .alive = true,
            };
            board[old_row * width + old_col] = @intCast(child_id);
            entities[entity_id].timer = timer;
            entity_count.* += 1;
        }
    } else {
        entities[entity_id].timer -= 1;
    }
}

fn predatorAction(entities: []Entity, entity_count: *usize, board: []i32,
                  entity_id: usize, width: usize, height: usize) void {
    const current = entities[entity_id].row * width + entities[entity_id].col;
    if (entities[entity_id].energy == 0) {
        board[current] = -1;
        entities[entity_id].alive = false;
        return;
    }
    const delta_rows = [_]i32{-1, 1, 0, 0}; // N, S, W, E
    const delta_cols = [_]i32{0, 0, -1, 1};
    var target: i32 = -1;
    for (0..4) |direction| {
        const row = @as(i32, @intCast(entities[entity_id].row)) + delta_rows[direction];
        const col = @as(i32, @intCast(entities[entity_id].col)) + delta_cols[direction];
        if (row < 0 or row >= @as(i32, @intCast(height)) or col < 0 or col >= @as(i32, @intCast(width))) continue;
        const cell = @as(usize, @intCast(row)) * width + @as(usize, @intCast(col));
        const occupant = board[cell];
        if (occupant != -1 and entities[@intCast(occupant)].kind == 1) {
            target = @intCast(cell);
            break;
        }
    }
    if (target >= 0) {
        const target_index: usize = @intCast(target);
        const prey_id: usize = @intCast(board[target_index]);
        entities[prey_id].alive = false;
        board[current] = -1;
        board[target_index] = @intCast(entity_id);
        entities[entity_id].row = target_index / width;
        entities[entity_id].col = target_index % width;
        entities[entity_id].energy += 5;
    } else {
        moveAndReproduce(entities, entity_count, board, entity_id, width, height);
    }
    entities[entity_id].energy -= 1;
}

export fn wa_tor(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 3 or length > 196) return -1;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_WIDTH)) or values[1] < 1 or values[1] > @as(i64, @intCast(MAX_HEIGHT)) or
        values[2] < 0 or values[2] > MAX_CHRONONS) return -1;
    const width: usize = @intCast(values[0]);
    const height: usize = @intCast(values[1]);
    const chronons: usize = @intCast(values[2]);
    const cell_count = width * height;
    if (length != 3 + 3 * cell_count) return -1;

    var entities = [_]Entity{.{ .kind = 0, .row = 0, .col = 0, .timer = 0, .energy = 0, .alive = false }} ** MAX_ENTITY_RECORDS;
    var entity_count: usize = 0;
    var board = [_]i32{-1} ** MAX_CELLS;
    var snapshot = [_]usize{0} ** MAX_CELLS;
    for (0..cell_count) |cell| {
        const kind = values[3 + 3 * cell];
        const timer = values[4 + 3 * cell];
        const energy = values[5 + 3 * cell];
        if (kind == 0) {
            if (timer != 0 or energy != 0) return -1;
            continue;
        }
        if (kind == 1) {
            if (timer < 0 or timer > 5 or energy != 0) return -1;
        } else if (kind == 2) {
            if (timer < 0 or timer > 20 or energy < 0 or energy > 15) return -1;
        } else {
            return -1;
        }
        entities[entity_count] = .{
            .kind = @intCast(kind),
            .row = cell / width,
            .col = cell % width,
            .timer = @intCast(timer),
            .energy = @intCast(energy),
            .alive = true,
        };
        board[cell] = @intCast(entity_count);
        entity_count += 1;
    }

    for (0..chronons) |_| {
        var snapshot_count: usize = 0;
        for (0..cell_count) |cell| {
            if (board[cell] != -1) {
                snapshot[snapshot_count] = @intCast(board[cell]);
                snapshot_count += 1;
            }
        }
        for (0..snapshot_count) |i| {
            const entity_id = snapshot[i];
            if (!entities[entity_id].alive) continue;
            if (entities[entity_id].kind == 1) {
                moveAndReproduce(entities[0..], &entity_count, board[0..], entity_id, width, height);
            } else {
                predatorAction(entities[0..], &entity_count, board[0..], entity_id, width, height);
            }
        }
    }

    var prey_count: i64 = 0;
    var predator_count: i64 = 0;
    var state_hash: i64 = 0;
    for (0..cell_count) |cell| {
        var code: i64 = 0;
        if (board[cell] != -1) {
            const entity = entities[@intCast(board[cell])];
            if (entity.kind == 1) {
                prey_count += 1;
                code = entity.timer + 33;
            } else {
                predator_count += 1;
                code = 1000 + 53 * entity.energy + entity.timer + 32;
            }
        }
        state_hash = @mod(state_hash * HASH_MULTIPLIER + code, HASH_MODULUS);
    }
    return state_hash * 4225 + 65 * prey_count + predator_count;
}
