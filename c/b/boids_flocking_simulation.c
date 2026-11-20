#include <stddef.h>
#include <stdint.h>

#define MAX_BOIDS 16
#define MAX_VALID_LENGTH 69
#define MAX_PARSEABLE_LENGTH 70
#define SEPARATION_SCALE 256

static int64_t trunc_zero(int64_t numerator, int64_t denominator) {
    return numerator < 0 ? -((-numerator) / denominator) : numerator / denominator;
}

static int64_t ceil_sqrt(int64_t value) {
    int64_t low = 0, high = 4096;
    while (low < high) {
        const int64_t middle = (low + high) / 2;
        if (middle * middle < value) low = middle + 1;
        else high = middle;
    }
    return low;
}

static void cap_vector(int64_t x, int64_t y, int64_t limit,
                       int64_t *out_x, int64_t *out_y) {
    const int64_t squared = x * x + y * y;
    if (squared <= limit * limit) { *out_x = x; *out_y = y; return; }
    if (limit == 0) { *out_x = 0; *out_y = 0; return; }
    const int64_t length = ceil_sqrt(squared);
    *out_x = trunc_zero(x * limit, length);
    *out_y = trunc_zero(y * limit, length);
}

static void request_acceleration(size_t index, size_t count,
        const int64_t *x, const int64_t *y, const int64_t *vx, const int64_t *vy,
        int64_t radius_squared, int64_t max_acceleration,
        int64_t *out_x, int64_t *out_y) {
    int64_t separation_x = 0, separation_y = 0;
    int64_t velocity_x = 0, velocity_y = 0;
    int64_t offset_x = 0, offset_y = 0;
    int64_t neighbors = 0;
    for (size_t other = 0; other < count; ++other) {
        if (other == index) continue;
        const int64_t dx = x[other] - x[index];
        const int64_t dy = y[other] - y[index];
        const int64_t distance_squared = dx * dx + dy * dy;
        if (distance_squared > radius_squared) continue;
        ++neighbors;
        if (distance_squared == 0) {
            separation_x += index < other ? -SEPARATION_SCALE : SEPARATION_SCALE;
        } else {
            const int64_t length = ceil_sqrt(distance_squared);
            separation_x += trunc_zero(-dx * SEPARATION_SCALE, length);
            separation_y += trunc_zero(-dy * SEPARATION_SCALE, length);
        }
        velocity_x += vx[other];
        velocity_y += vy[other];
        offset_x += dx;
        offset_y += dy;
    }
    if (neighbors == 0) { *out_x = 0; *out_y = 0; return; }

    int64_t request_x[3], request_y[3];
    cap_vector(trunc_zero(separation_x, neighbors),
               trunc_zero(separation_y, neighbors), max_acceleration,
               &request_x[0], &request_y[0]);
    cap_vector(trunc_zero(velocity_x, neighbors) - vx[index],
               trunc_zero(velocity_y, neighbors) - vy[index], max_acceleration,
               &request_x[1], &request_y[1]);
    cap_vector(trunc_zero(offset_x, neighbors),
               trunc_zero(offset_y, neighbors), max_acceleration,
               &request_x[2], &request_y[2]);

    int64_t used = 0, accel_x = 0, accel_y = 0;
    for (size_t rule = 0; rule < 3; ++rule) {
        const int64_t remaining = max_acceleration - used;
        if (remaining <= 0) break;
        const int64_t length = ceil_sqrt(request_x[rule] * request_x[rule]
                                      + request_y[rule] * request_y[rule]);
        if (length == 0) continue;
        if (length <= remaining) {
            accel_x += request_x[rule]; accel_y += request_y[rule]; used += length;
        } else {
            int64_t trimmed_x, trimmed_y;
            cap_vector(request_x[rule], request_y[rule], remaining, &trimmed_x, &trimmed_y);
            accel_x += trimmed_x; accel_y += trimmed_y;
            break;
        }
    }
    *out_x = accel_x; *out_y = accel_y;
}

static void store_i32_le(uint8_t *output, size_t offset, int64_t value) {
    const uint32_t bits = (uint32_t)(int32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t boids_flocking_simulation(const int64_t *input, size_t length,
                                  uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 9 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t count_value = input[0], steps = input[1], radius = input[2];
    const int64_t max_speed = input[3], max_acceleration = input[4];
    if (count_value < 1 || count_value > MAX_BOIDS || steps < 0 || steps > 16
        || radius < 0 || radius > 128 || max_speed < 1 || max_speed > 32
        || max_acceleration < 0 || max_acceleration > 8
        || length != 5 + 4 * (size_t)count_value) return -1;
    const size_t count = (size_t)count_value;
    int64_t x[MAX_BOIDS] = {0}, y[MAX_BOIDS] = {0};
    int64_t vx[MAX_BOIDS] = {0}, vy[MAX_BOIDS] = {0};
    int64_t next_x[MAX_BOIDS] = {0}, next_y[MAX_BOIDS] = {0};
    int64_t next_vx[MAX_BOIDS] = {0}, next_vy[MAX_BOIDS] = {0};
    for (size_t i = 0; i < count; ++i) {
        x[i] = input[5 + 4 * i]; y[i] = input[6 + 4 * i];
        vx[i] = input[7 + 4 * i]; vy[i] = input[8 + 4 * i];
        if (x[i] < -256 || x[i] > 256 || y[i] < -256 || y[i] > 256
            || vx[i] < -32 || vx[i] > 32 || vy[i] < -32 || vy[i] > 32
            || vx[i] * vx[i] + vy[i] * vy[i] > max_speed * max_speed) return -1;
    }
    const size_t needed = 16 * count;
    if (output == NULL || output_capacity < needed) return -2;
    const int64_t radius_squared = radius * radius;
    for (int64_t step = 0; step < steps; ++step) {
        for (size_t i = 0; i < count; ++i) {
            int64_t accel_x, accel_y;
            request_acceleration(i, count, x, y, vx, vy, radius_squared,
                                 max_acceleration, &accel_x, &accel_y);
            cap_vector(vx[i] + accel_x, vy[i] + accel_y, max_speed,
                       &next_vx[i], &next_vy[i]);
            next_x[i] = x[i] + next_vx[i];
            next_y[i] = y[i] + next_vy[i];
        }
        for (size_t i = 0; i < count; ++i) {
            x[i] = next_x[i]; y[i] = next_y[i];
            vx[i] = next_vx[i]; vy[i] = next_vy[i];
        }
    }
    for (size_t i = 0; i < count; ++i) {
        const size_t offset = 16 * i;
        store_i32_le(output, offset, x[i]);
        store_i32_le(output, offset + 4, y[i]);
        store_i32_le(output, offset + 8, vx[i]);
        store_i32_le(output, offset + 12, vy[i]);
    }
    return (int64_t)needed;
}
