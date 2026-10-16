#include <cstddef>
#include <cstdint>

static constexpr int MAX_WIDTH = 8;
static constexpr int MAX_HEIGHT = 8;
static constexpr int MAX_CELLS = 64;
static constexpr int MAX_CHRONONS = 32;
static constexpr int MAX_ENTITY_RECORDS = MAX_CELLS * (MAX_CHRONONS + 1);
static constexpr std::int64_t HASH_MODULUS = 2147483647LL;
static constexpr std::int64_t HASH_MULTIPLIER = 1000003LL;

struct Entity {
    int kind;
    int row;
    int col;
    int timer;
    int energy;
    bool alive;
};

static int breed_time(int kind) {
    return kind == 1 ? 5 : 20;
}

static void move_and_reproduce(Entity* entities, int& entity_count, int* board,
                               int entity_id, int width, int height) {
    Entity& entity = entities[entity_id];
    const int old_row = entity.row;
    const int old_col = entity.col;
    const int delta_rows[4] = {-1, 0, 1, 0}; // N, E, S, W
    const int delta_cols[4] = {0, 1, 0, -1};
    bool moved = false;
    for (int direction = 0; direction < 4; ++direction) {
        const int row = old_row + delta_rows[direction];
        const int col = old_col + delta_cols[direction];
        if (row < 0 || row >= height || col < 0 || col >= width) continue;
        const int destination = row * width + col;
        if (board[destination] != -1) continue;
        board[old_row * width + old_col] = -1;
        board[destination] = entity_id;
        entity.row = row;
        entity.col = col;
        moved = true;
        break;
    }
    if (moved && entity.timer <= 0) {
        if (entity_count < MAX_ENTITY_RECORDS) {
            const int child_id = entity_count++;
            entities[child_id] = {entity.kind, old_row, old_col, breed_time(entity.kind),
                                  entity.kind == 1 ? 0 : 15, true};
            board[old_row * width + old_col] = child_id;
            entity.timer = breed_time(entity.kind);
        }
    } else {
        --entity.timer;
    }
}

static void predator_action(Entity* entities, int& entity_count, int* board,
                            int entity_id, int width, int height) {
    Entity& entity = entities[entity_id];
    const int current = entity.row * width + entity.col;
    if (entity.energy == 0) {
        board[current] = -1;
        entity.alive = false;
        return;
    }
    const int delta_rows[4] = {-1, 1, 0, 0}; // N, S, W, E
    const int delta_cols[4] = {0, 0, -1, 1};
    int target = -1;
    for (int direction = 0; direction < 4; ++direction) {
        const int row = entity.row + delta_rows[direction];
        const int col = entity.col + delta_cols[direction];
        if (row < 0 || row >= height || col < 0 || col >= width) continue;
        const int cell = row * width + col;
        const int occupant = board[cell];
        if (occupant != -1 && entities[occupant].kind == 1) {
            target = cell;
            break;
        }
    }
    if (target != -1) {
        const int prey_id = board[target];
        entities[prey_id].alive = false;
        board[current] = -1;
        board[target] = entity_id;
        entity.row = target / width;
        entity.col = target % width;
        entity.energy += 5;
    } else {
        move_and_reproduce(entities, entity_count, board, entity_id, width, height);
    }
    --entity.energy;
}

extern "C" std::int64_t wa_tor(const std::int64_t* values, std::size_t length) {
    if (values == nullptr || length < 3 || length > 3 + 3 * MAX_CELLS + 1) return -1;
    const std::int64_t width_value = values[0];
    const std::int64_t height_value = values[1];
    const std::int64_t chronon_value = values[2];
    if (width_value < 1 || width_value > MAX_WIDTH || height_value < 1 || height_value > MAX_HEIGHT ||
        chronon_value < 0 || chronon_value > MAX_CHRONONS) return -1;
    const int width = static_cast<int>(width_value);
    const int height = static_cast<int>(height_value);
    const int chronons = static_cast<int>(chronon_value);
    const int cell_count = width * height;
    if (length != static_cast<std::size_t>(3 + 3 * cell_count)) return -1;

    Entity entities[MAX_ENTITY_RECORDS] = {};
    int entity_count = 0;
    int board[MAX_CELLS];
    int snapshot[MAX_CELLS];
    for (int cell = 0; cell < cell_count; ++cell) board[cell] = -1;
    for (int cell = 0; cell < cell_count; ++cell) {
        const std::int64_t kind = values[3 + 3 * cell];
        const std::int64_t timer = values[4 + 3 * cell];
        const std::int64_t energy = values[5 + 3 * cell];
        if (kind == 0) {
            if (timer != 0 || energy != 0) return -1;
            continue;
        }
        if (kind == 1) {
            if (timer < 0 || timer > 5 || energy != 0) return -1;
        } else if (kind == 2) {
            if (timer < 0 || timer > 20 || energy < 0 || energy > 15) return -1;
        } else {
            return -1;
        }
        entities[entity_count] = {static_cast<int>(kind), cell / width, cell % width,
                                  static_cast<int>(timer), static_cast<int>(energy), true};
        board[cell] = entity_count++;
    }

    for (int chronon = 0; chronon < chronons; ++chronon) {
        int snapshot_count = 0;
        for (int cell = 0; cell < cell_count; ++cell) {
            if (board[cell] != -1) snapshot[snapshot_count++] = board[cell];
        }
        for (int i = 0; i < snapshot_count; ++i) {
            const int entity_id = snapshot[i];
            Entity& entity = entities[entity_id];
            if (!entity.alive) continue;
            if (entity.kind == 1) {
                move_and_reproduce(entities, entity_count, board, entity_id, width, height);
            } else {
                predator_action(entities, entity_count, board, entity_id, width, height);
            }
        }
    }

    int prey_count = 0;
    int predator_count = 0;
    std::int64_t state_hash = 0;
    for (int cell = 0; cell < cell_count; ++cell) {
        std::int64_t code = 0;
        if (board[cell] != -1) {
            const Entity& entity = entities[board[cell]];
            if (entity.kind == 1) {
                ++prey_count;
                code = entity.timer + 33;
            } else {
                ++predator_count;
                code = 1000 + 53LL * entity.energy + entity.timer + 32;
            }
        }
        state_hash = (state_hash * HASH_MULTIPLIER + code) % HASH_MODULUS;
    }
    return state_hash * 4225 + 65LL * prey_count + predator_count;
}
