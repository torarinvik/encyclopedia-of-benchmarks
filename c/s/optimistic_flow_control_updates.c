#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 3, MAX_L = 4, MAX_INPUT = 20, MAX_OUTPUT = 48, MAX_UPDATES = 6, SCALE = 46656 };

static int64_t gcd64(int64_t a, int64_t b)
{
    while (b != 0) { int64_t remainder = a % b; a = b; b = remainder; }
    return a;
}

static bool update_session(size_t session, size_t n, size_t links,
                           const int64_t capacity[MAX_L], const bool path[MAX_N][MAX_L],
                           int64_t rate[MAX_N], size_t *bottleneck_out)
{
    int64_t best = INT64_MAX;
    size_t bottleneck = links;
    for (size_t link = 0; link < links; ++link) {
        if (!path[session][link]) continue;
        int64_t fixed = 0;
        size_t active = 1;
        for (size_t other = 0; other < n; ++other) if (other != session && path[other][link]) {
            if (rate[other] <= rate[session]) fixed += rate[other];
            else ++active;
        }
        int64_t level = rate[session];
        int64_t candidate = level;
        for (size_t pass = 0; pass < n; ++pass) {
            int64_t numerator = capacity[link] * SCALE - fixed;
            if (numerator < 0 || numerator % (int64_t)active != 0) return false;
            candidate = numerator / (int64_t)active;
            if (candidate < level) return false;
            int64_t next_level = INT64_MAX;
            for (size_t other = 0; other < n; ++other)
                if (other != session && path[other][link] && rate[other] > level && rate[other] < next_level)
                    next_level = rate[other];
            if (next_level == INT64_MAX || candidate <= next_level) break;
            size_t saturated = 0;
            for (size_t other = 0; other < n; ++other)
                if (other != session && path[other][link] && rate[other] == next_level) ++saturated;
            fixed += (int64_t)saturated * next_level;
            active -= saturated;
            level = next_level;
        }
        if (candidate < best) { best = candidate; bottleneck = link; }
    }
    if (bottleneck == links) return false;
    rate[session] = best;
    for (size_t other = 0; other < n; ++other)
        if (other != session && path[other][bottleneck] && rate[other] > best) rate[other] = best;
    *bottleneck_out = bottleneck;
    return true;
}

static size_t choose_session(size_t mode, size_t step, size_t n, size_t links,
                             const int64_t capacity[MAX_L], const bool path[MAX_N][MAX_L],
                             const int64_t rate[MAX_N])
{
    if (mode == 0) return step % n;
    if (mode == 1) {
        size_t best = 0;
        for (size_t s = 1; s < n; ++s) if (rate[s] < rate[best]) best = s;
        return best;
    }
    if (mode == 2) {
        for (size_t s = 0; s < n; ++s) {
            bool local = true;
            for (size_t other = 0; other < n && local; ++other) if (other != s) {
                bool shares = false;
                for (size_t link = 0; link < links; ++link)
                    if (path[s][link] && path[other][link]) shares = true;
                if (shares && (rate[other] < rate[s] || (rate[other] == rate[s] && other < s))) local = false;
            }
            if (local) return s;
        }
        return 0;
    }
    size_t congested = links;
    int64_t best_load = 0;
    for (size_t link = 0; link < links; ++link) {
        int64_t load = 0;
        bool used = false;
        for (size_t s = 0; s < n; ++s) if (path[s][link]) { load += rate[s]; used = true; }
        if (used && (congested == links || load * capacity[congested] > best_load * capacity[link])) {
            congested = link; best_load = load;
        }
    }
    for (size_t s = 0; s < n; ++s) if (path[s][congested]) return s;
    return 0;
}

static void put64(uint8_t *output, size_t position, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[position + byte] = (uint8_t)(bits >> (8u * byte));
}

int64_t optimistic_flow_control_updates(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 7u || length > MAX_INPUT) return -1;
    int64_t n64 = input[0], l64 = input[1], mode64 = input[2], q64 = input[3];
    if (n64 < 2 || n64 > MAX_N || l64 < 1 || l64 > MAX_L || mode64 < 0 || mode64 > 3 || q64 < 1 || q64 > MAX_UPDATES) return -1;
    size_t n = (size_t)n64, links = (size_t)l64, mode = (size_t)mode64, updates = (size_t)q64;
    if (length != 4u + links + n * links) return -1;
    int64_t link_capacity[MAX_L] = {0};
    bool path[MAX_N][MAX_L] = {{false}};
    int64_t rate[MAX_N] = {0};
    for (size_t link = 0; link < links; ++link) {
        link_capacity[link] = input[4u + link];
        if (link_capacity[link] < 1 || link_capacity[link] > 16) return -1;
    }
    for (size_t session = 0; session < n; ++session) {
        bool uses_link = false;
        for (size_t link = 0; link < links; ++link) {
            int64_t value = input[4u + links + session * links + link];
            if (value != 0 && value != 1) return -1;
            path[session][link] = value == 1;
            uses_link = uses_link || value == 1;
        }
        if (!uses_link) return -1;
    }
    size_t output_bytes = 16u * n;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t step = 0; step < updates; ++step) {
        size_t session = choose_session(mode, step, n, links, link_capacity, path, rate);
        size_t bottleneck = links;
        if (!update_session(session, n, links, link_capacity, path, rate, &bottleneck)) return -1;
    }
    uint8_t staged[MAX_OUTPUT] = {0};
    for (size_t session = 0; session < n; ++session) {
        int64_t divisor = gcd64(rate[session], SCALE);
        put64(staged, 16u * session, rate[session] / divisor);
        put64(staged, 16u * session + 8u, SCALE / divisor);
    }
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
