const MAX_WIDTH: usize = 8;
const MAX_HEIGHT: usize = 8;
const MAX_CELLS: usize = 64;
const MAX_CHRONONS: usize = 32;
const MAX_ENTITY_RECORDS: usize = MAX_CELLS * (MAX_CHRONONS + 1);
const HASH_MODULUS: i64 = 2_147_483_647;
const HASH_MULTIPLIER: i64 = 1_000_003;

#[derive(Clone, Copy)]
struct Entity {
    kind: i32,
    row: usize,
    col: usize,
    timer: i32,
    energy: i32,
    alive: bool,
}

const EMPTY_ENTITY: Entity = Entity { kind: 0, row: 0, col: 0, timer: 0, energy: 0, alive: false };

fn breed_time(kind: i32) -> i32 {
    if kind == 1 { 5 } else { 20 }
}

fn move_and_reproduce(entities: &mut [Entity; MAX_ENTITY_RECORDS], entity_count: &mut usize,
                      board: &mut [i32; MAX_CELLS], entity_id: usize, width: usize, height: usize) {
    let old_row = entities[entity_id].row;
    let old_col = entities[entity_id].col;
    let delta_rows = [-1i32, 0, 1, 0]; // N, E, S, W
    let delta_cols = [0i32, 1, 0, -1];
    let mut moved = false;
    for direction in 0..4 {
        let row = old_row as i32 + delta_rows[direction];
        let col = old_col as i32 + delta_cols[direction];
        if row < 0 || row >= height as i32 || col < 0 || col >= width as i32 { continue; }
        let destination = row as usize * width + col as usize;
        if board[destination] != -1 { continue; }
        board[old_row * width + old_col] = -1;
        board[destination] = entity_id as i32;
        entities[entity_id].row = row as usize;
        entities[entity_id].col = col as usize;
        moved = true;
        break;
    }
    if moved && entities[entity_id].timer <= 0 {
        if *entity_count < MAX_ENTITY_RECORDS {
            let child_id = *entity_count;
            let kind = entities[entity_id].kind;
            let timer = breed_time(kind);
            entities[child_id] = Entity {
                kind,
                row: old_row,
                col: old_col,
                timer,
                energy: if kind == 1 { 0 } else { 15 },
                alive: true,
            };
            board[old_row * width + old_col] = child_id as i32;
            entities[entity_id].timer = timer;
            *entity_count += 1;
        }
    } else {
        entities[entity_id].timer -= 1;
    }
}

fn predator_action(entities: &mut [Entity; MAX_ENTITY_RECORDS], entity_count: &mut usize,
                   board: &mut [i32; MAX_CELLS], entity_id: usize, width: usize, height: usize) {
    let current = entities[entity_id].row * width + entities[entity_id].col;
    if entities[entity_id].energy == 0 {
        board[current] = -1;
        entities[entity_id].alive = false;
        return;
    }
    let delta_rows = [-1i32, 1, 0, 0]; // N, S, W, E
    let delta_cols = [0i32, 0, -1, 1];
    let mut target = -1i32;
    for direction in 0..4 {
        let row = entities[entity_id].row as i32 + delta_rows[direction];
        let col = entities[entity_id].col as i32 + delta_cols[direction];
        if row < 0 || row >= height as i32 || col < 0 || col >= width as i32 { continue; }
        let cell = row as usize * width + col as usize;
        let occupant = board[cell];
        if occupant != -1 && entities[occupant as usize].kind == 1 {
            target = cell as i32;
            break;
        }
    }
    if target != -1 {
        let target = target as usize;
        let prey_id = board[target] as usize;
        entities[prey_id].alive = false;
        board[current] = -1;
        board[target] = entity_id as i32;
        entities[entity_id].row = target / width;
        entities[entity_id].col = target % width;
        entities[entity_id].energy += 5;
    } else {
        move_and_reproduce(entities, entity_count, board, entity_id, width, height);
    }
    entities[entity_id].energy -= 1;
}

#[no_mangle]
pub unsafe extern "C" fn wa_tor(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 || length > 196 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 1 || input[0] > MAX_WIDTH as i64 || input[1] < 1 || input[1] > MAX_HEIGHT as i64 ||
        input[2] < 0 || input[2] > MAX_CHRONONS as i64 { return -1; }
    let width = input[0] as usize;
    let height = input[1] as usize;
    let chronons = input[2] as usize;
    let cell_count = width * height;
    if length != 3 + 3 * cell_count { return -1; }

    let mut entities = [EMPTY_ENTITY; MAX_ENTITY_RECORDS];
    let mut entity_count = 0usize;
    let mut board = [-1i32; MAX_CELLS];
    let mut snapshot = [0usize; MAX_CELLS];
    for cell in 0..cell_count {
        let kind = input[3 + 3 * cell];
        let timer = input[4 + 3 * cell];
        let energy = input[5 + 3 * cell];
        if kind == 0 {
            if timer != 0 || energy != 0 { return -1; }
            continue;
        }
        if kind == 1 {
            if timer < 0 || timer > 5 || energy != 0 { return -1; }
        } else if kind == 2 {
            if timer < 0 || timer > 20 || energy < 0 || energy > 15 { return -1; }
        } else {
            return -1;
        }
        entities[entity_count] = Entity {
            kind: kind as i32,
            row: cell / width,
            col: cell % width,
            timer: timer as i32,
            energy: energy as i32,
            alive: true,
        };
        board[cell] = entity_count as i32;
        entity_count += 1;
    }

    for _ in 0..chronons {
        let mut snapshot_count = 0usize;
        for cell in 0..cell_count {
            if board[cell] != -1 {
                snapshot[snapshot_count] = board[cell] as usize;
                snapshot_count += 1;
            }
        }
        for i in 0..snapshot_count {
            let entity_id = snapshot[i];
            if !entities[entity_id].alive { continue; }
            if entities[entity_id].kind == 1 {
                move_and_reproduce(&mut entities, &mut entity_count, &mut board, entity_id, width, height);
            } else {
                predator_action(&mut entities, &mut entity_count, &mut board, entity_id, width, height);
            }
        }
    }

    let mut prey_count = 0i64;
    let mut predator_count = 0i64;
    let mut state_hash = 0i64;
    for cell in 0..cell_count {
        let mut code = 0i64;
        if board[cell] != -1 {
            let entity = entities[board[cell] as usize];
            if entity.kind == 1 {
                prey_count += 1;
                code = (entity.timer + 33) as i64;
            } else {
                predator_count += 1;
                code = 1000 + 53 * entity.energy as i64 + entity.timer as i64 + 32;
            }
        }
        state_hash = (state_hash * HASH_MULTIPLIER + code) % HASH_MODULUS;
    }
    state_hash * 4225 + 65 * prey_count + predator_count
}
