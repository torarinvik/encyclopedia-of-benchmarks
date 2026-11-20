#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_boids = 16;
constexpr std::int64_t separation_scale = 256;

std::int64_t trunc_zero(std::int64_t numerator, std::int64_t denominator) {
    return numerator < 0 ? -((-numerator) / denominator) : numerator / denominator;
}

std::int64_t ceil_sqrt(std::int64_t value) {
    std::int64_t low = 0, high = 4096;
    while (low < high) {
        const auto middle = (low + high) / 2;
        if (middle * middle < value) low = middle + 1;
        else high = middle;
    }
    return low;
}

std::array<std::int64_t, 2> cap_vector(std::int64_t x, std::int64_t y,
                                      std::int64_t limit) {
    const auto squared = x * x + y * y;
    if (squared <= limit * limit) return {x, y};
    if (limit == 0) return {0, 0};
    const auto length = ceil_sqrt(squared);
    return {trunc_zero(x * limit, length), trunc_zero(y * limit, length)};
}

std::array<std::int64_t, 2> request_acceleration(std::size_t index,
        std::size_t count, const std::array<std::int64_t, max_boids>& x,
        const std::array<std::int64_t, max_boids>& y,
        const std::array<std::int64_t, max_boids>& vx,
        const std::array<std::int64_t, max_boids>& vy,
        std::int64_t radius_squared, std::int64_t max_acceleration) {
    std::int64_t sx = 0, sy = 0, vx_sum = 0, vy_sum = 0, ox = 0, oy = 0;
    std::int64_t neighbors = 0;
    for (std::size_t other = 0; other < count; ++other) {
        if (other == index) continue;
        const auto dx = x[other] - x[index], dy = y[other] - y[index];
        const auto d2 = dx * dx + dy * dy;
        if (d2 > radius_squared) continue;
        ++neighbors;
        if (d2 == 0) sx += index < other ? -separation_scale : separation_scale;
        else {
            const auto length = ceil_sqrt(d2);
            sx += trunc_zero(-dx * separation_scale, length);
            sy += trunc_zero(-dy * separation_scale, length);
        }
        vx_sum += vx[other]; vy_sum += vy[other]; ox += dx; oy += dy;
    }
    if (neighbors == 0) return {0, 0};
    const std::array<std::array<std::int64_t, 2>, 3> requests = {
        cap_vector(trunc_zero(sx, neighbors), trunc_zero(sy, neighbors), max_acceleration),
        cap_vector(trunc_zero(vx_sum, neighbors) - vx[index],
                   trunc_zero(vy_sum, neighbors) - vy[index], max_acceleration),
        cap_vector(trunc_zero(ox, neighbors), trunc_zero(oy, neighbors), max_acceleration)
    };
    std::int64_t ax = 0, ay = 0, used = 0;
    for (const auto& request : requests) {
        const auto remaining = max_acceleration - used;
        if (remaining <= 0) break;
        const auto length = ceil_sqrt(request[0] * request[0] + request[1] * request[1]);
        if (length == 0) continue;
        if (length <= remaining) { ax += request[0]; ay += request[1]; used += length; }
        else {
            const auto trimmed = cap_vector(request[0], request[1], remaining);
            ax += trimmed[0]; ay += trimmed[1];
            break;
        }
    }
    return {ax, ay};
}

void store_i32_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t boids_flocking_simulation(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 9 || length > 70) return -1;
    const auto n_value = input[0], steps = input[1], radius = input[2];
    const auto max_speed = input[3], max_acceleration = input[4];
    if (n_value < 1 || n_value > 16 || steps < 0 || steps > 16
        || radius < 0 || radius > 128 || max_speed < 1 || max_speed > 32
        || max_acceleration < 0 || max_acceleration > 8
        || length != 5 + 4 * static_cast<std::size_t>(n_value)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    std::array<std::int64_t, max_boids> x{}, y{}, vx{}, vy{}, nx{}, ny{}, nvx{}, nvy{};
    for (std::size_t i = 0; i < n; ++i) {
        x[i] = input[5 + 4 * i]; y[i] = input[6 + 4 * i];
        vx[i] = input[7 + 4 * i]; vy[i] = input[8 + 4 * i];
        if (x[i] < -256 || x[i] > 256 || y[i] < -256 || y[i] > 256
            || vx[i] < -32 || vx[i] > 32 || vy[i] < -32 || vy[i] > 32
            || vx[i] * vx[i] + vy[i] * vy[i] > max_speed * max_speed) return -1;
    }
    const auto needed = 16 * n;
    if (output == nullptr || output_capacity < needed) return -2;
    const auto radius_squared = radius * radius;
    for (std::int64_t step = 0; step < steps; ++step) {
        for (std::size_t i = 0; i < n; ++i) {
            const auto acceleration = request_acceleration(i, n, x, y, vx, vy,
                                                            radius_squared, max_acceleration);
            const auto velocity = cap_vector(vx[i] + acceleration[0], vy[i] + acceleration[1], max_speed);
            nvx[i] = velocity[0]; nvy[i] = velocity[1];
            nx[i] = x[i] + nvx[i]; ny[i] = y[i] + nvy[i];
        }
        for (std::size_t i = 0; i < n; ++i) {
            x[i] = nx[i]; y[i] = ny[i]; vx[i] = nvx[i]; vy[i] = nvy[i];
        }
    }
    for (std::size_t i = 0; i < n; ++i) {
        store_i32_le(output, 16 * i, x[i]); store_i32_le(output, 16 * i + 4, y[i]);
        store_i32_le(output, 16 * i + 8, vx[i]); store_i32_le(output, 16 * i + 12, vy[i]);
    }
    return static_cast<std::int64_t>(needed);
}
