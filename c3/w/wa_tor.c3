module wa_tor;

const int MAX_WIDTH = 8;
const int MAX_HEIGHT = 8;
const int MAX_CELLS = 64;
const int MAX_CHRONONS = 32;
const int MAX_ENTITY_RECORDS = MAX_CELLS * (MAX_CHRONONS + 1);
const long HASH_MODULUS = 2147483647L;
const long HASH_MULTIPLIER = 1000003L;

struct Entity { int kind; int row; int col; int timer; int energy; bool alive; }

fn int breed_time(int kind) { return kind == 1 ? 5 : 20; }

fn void move_and_reproduce(Entity* entities, int* entity_count, int* board,
                           int entity_id, int width, int height) {
    Entity* entity = &entities[entity_id];
    int old_row = entity.row; int old_col = entity.col;
    int[4] delta_rows = {-1, 0, 1, 0};
    int[4] delta_cols = {0, 1, 0, -1};
    bool moved = false;
    for (int direction = 0; direction < 4; direction++) {
        int row = old_row + delta_rows[direction];
        int col = old_col + delta_cols[direction];
        if (row < 0 || row >= height || col < 0 || col >= width) continue;
        int destination = row * width + col;
        if (board[destination] != -1) continue;
        board[old_row * width + old_col] = -1;
        board[destination] = entity_id;
        entity.row = row; entity.col = col; moved = true;
        break;
    }
    if (moved && entity.timer <= 0) {
        if (entity_count[0] < MAX_ENTITY_RECORDS) {
            int child_id = entity_count[0];
            entities[child_id].kind = entity.kind;
            entities[child_id].row = old_row;
            entities[child_id].col = old_col;
            entities[child_id].timer = breed_time(entity.kind);
            entities[child_id].energy = entity.kind == 1 ? 0 : 15;
            entities[child_id].alive = true;
            board[old_row * width + old_col] = child_id;
            entity.timer = breed_time(entity.kind);
            entity_count[0]++;
        }
    } else {
        entity.timer--;
    }
}

fn void predator_action(Entity* entities, int* entity_count, int* board,
                        int entity_id, int width, int height) {
    Entity* entity = &entities[entity_id];
    int current = entity.row * width + entity.col;
    if (entity.energy == 0) {
        board[current] = -1;
        entity.alive = false;
        return;
    }
    int[4] delta_rows = {-1, 1, 0, 0};
    int[4] delta_cols = {0, 0, -1, 1};
    int target = -1;
    for (int direction = 0; direction < 4; direction++) {
        int row = entity.row + delta_rows[direction];
        int col = entity.col + delta_cols[direction];
        if (row < 0 || row >= height || col < 0 || col >= width) continue;
        int cell = row * width + col;
        int occupant = board[cell];
        if (occupant != -1 && entities[occupant].kind == 1) { target = cell; break; }
    }
    if (target != -1) {
        int prey_id = board[target];
        entities[prey_id].alive = false;
        board[current] = -1;
        board[target] = entity_id;
        entity.row = target / width;
        entity.col = target % width;
        entity.energy += 5;
    } else {
        move_and_reproduce(entities, entity_count, board, entity_id, width, height);
    }
    entity.energy--;
}

fn long wa_tor(long* values, usz length) @export("wa_tor") {
    if (values == null || length < 3 || length > 196) return -1;
    long width_value = values[0]; long height_value = values[1]; long chronon_value = values[2];
    if (width_value < 1 || width_value > MAX_WIDTH || height_value < 1 || height_value > MAX_HEIGHT ||
        chronon_value < 0 || chronon_value > MAX_CHRONONS) return -1;
    int width = (int)width_value; int height = (int)height_value; int chronons = (int)chronon_value;
    int cell_count = width * height;
    if (length != (usz)(3 + 3 * cell_count)) return -1;

    Entity[MAX_ENTITY_RECORDS] entities = {};
    int entity_count = 0;
    int[MAX_CELLS] board; int[MAX_CELLS] snapshot;
    for (int cell = 0; cell < cell_count; cell++) board[cell] = -1;
    for (int cell = 0; cell < cell_count; cell++) {
        long kind = values[3 + 3 * cell]; long timer = values[4 + 3 * cell]; long energy = values[5 + 3 * cell];
        if (kind == 0) { if (timer != 0 || energy != 0) return -1; continue; }
        if (kind == 1) { if (timer < 0 || timer > 5 || energy != 0) return -1; }
        else if (kind == 2) { if (timer < 0 || timer > 20 || energy < 0 || energy > 15) return -1; }
        else return -1;
        entities[entity_count].kind = (int)kind;
        entities[entity_count].row = cell / width;
        entities[entity_count].col = cell % width;
        entities[entity_count].timer = (int)timer;
        entities[entity_count].energy = (int)energy;
        entities[entity_count].alive = true;
        board[cell] = entity_count++;
    }

    for (int chronon = 0; chronon < chronons; chronon++) {
        int snapshot_count = 0;
        for (int cell = 0; cell < cell_count; cell++) if (board[cell] != -1) snapshot[snapshot_count++] = board[cell];
        for (int i = 0; i < snapshot_count; i++) {
            int entity_id = snapshot[i];
            if (!entities[entity_id].alive) continue;
            if (entities[entity_id].kind == 1) move_and_reproduce(&entities[0], &entity_count, &board[0], entity_id, width, height);
            else predator_action(&entities[0], &entity_count, &board[0], entity_id, width, height);
        }
    }

    int prey_count = 0; int predator_count = 0; long state_hash = 0;
    for (int cell = 0; cell < cell_count; cell++) {
        long code = 0;
        if (board[cell] != -1) {
            Entity* entity = &entities[board[cell]];
            if (entity.kind == 1) { prey_count++; code = entity.timer + 33; }
            else { predator_count++; code = 1000L + 53L * entity.energy + entity.timer + 32; }
        }
        state_hash = (state_hash * HASH_MULTIPLIER + code) % HASH_MODULUS;
    }
    return state_hash * 4225L + 65L * prey_count + predator_count;
}
