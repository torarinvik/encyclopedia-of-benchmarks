#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr int kMaxOperations = 128;
constexpr int kMaxLive = 64;
constexpr int kMaxBuckets = 64;
constexpr std::int64_t kMaxPriority = 1'000'000;
constexpr std::size_t kMaxInput = 1 + 2 * kMaxOperations + 1;

struct Event {
    std::int64_t priority = 0;
    std::int64_t id = 0;
    int next = -1;
    bool active = false;
};

struct Calendar {
    std::array<Event, kMaxLive> events{};
    std::array<int, kMaxBuckets> heads{};
    int bucket_count = 2;
    int live_count = 0;
    std::int64_t next_id = 0;
    std::int64_t last_priority = 0;
    int last_bucket = 0;
    std::int64_t width_num = 1;
    std::int64_t width_den = 1;
    std::int64_t top_num = 3;
    std::int64_t top_den = 2;

    Calendar() { heads.fill(-1); }

    static bool less(const Event& a, const Event& b) {
        return a.priority < b.priority || (a.priority == b.priority && a.id < b.id);
    }

    std::int64_t virtual_bucket(std::int64_t priority) const {
        return priority * width_den / width_num;
    }

    int bucket_index(std::int64_t priority) const {
        return static_cast<int>(virtual_bucket(priority) % bucket_count);
    }

    void reset_cursor(std::int64_t priority) {
        const std::int64_t virtual_index = virtual_bucket(priority);
        last_bucket = static_cast<int>(virtual_index % bucket_count);
        top_num = (2 * virtual_index + 3) * width_num;
        top_den = 2 * width_den;
    }

    void insert_slot(int slot) {
        const int b = bucket_index(events[slot].priority);
        int previous = -1;
        int current = heads[b];
        while (current >= 0 && less(events[current], events[slot])) {
            previous = current;
            current = events[current].next;
        }
        events[slot].next = current;
        if (previous < 0) heads[b] = slot;
        else events[previous].next = slot;
    }

    std::pair<std::int64_t, std::int64_t> new_width() const {
        std::array<Event, kMaxLive> ordered{};
        int count = 0;
        for (const Event& event : events) {
            if (!event.active) continue;
            int at = count;
            while (at > 0 && less(event, ordered[at - 1])) {
                ordered[at] = ordered[at - 1];
                --at;
            }
            ordered[at] = event;
            ++count;
        }
        if (count < 2) return {1, 1};
        int samples = count <= 5 ? count : 5 + count / 10;
        if (samples > 25) samples = 25;
        std::int64_t gap_sum = 0;
        for (int i = 0; i + 1 < samples; ++i) {
            gap_sum += ordered[i + 1].priority - ordered[i].priority;
        }
        const int gap_count = samples - 1;
        if (gap_sum == 0) return {1, 1};
        std::int64_t kept_sum = 0;
        int kept_count = 0;
        for (int i = 0; i < gap_count; ++i) {
            const std::int64_t gap = ordered[i + 1].priority - ordered[i].priority;
            if (gap * gap_count <= 2 * gap_sum) {
                kept_sum += gap;
                ++kept_count;
            }
        }
        if (kept_sum == 0 || kept_count == 0) return {1, 1};
        std::int64_t numerator = 3 * kept_sum;
        std::int64_t denominator = kept_count;
        auto gcd = [](std::int64_t a, std::int64_t b) {
            while (b != 0) { const auto r = a % b; a = b; b = r; }
            return a;
        };
        const auto divisor = gcd(numerator, denominator);
        return {numerator / divisor, denominator / divisor};
    }

    void resize(int new_count) {
        const auto [new_num, new_den] = new_width();
        width_num = new_num;
        width_den = new_den;
        bucket_count = new_count;
        heads.fill(-1);
        reset_cursor(last_priority);
        for (int slot = 0; slot < kMaxLive; ++slot) {
            if (events[slot].active) insert_slot(slot);
        }
    }

    bool enqueue(std::int64_t priority) {
        if (priority < 0 || priority > kMaxPriority || priority < last_priority
                || live_count >= kMaxLive) return false;
        int slot = -1;
        for (int i = 0; i < kMaxLive; ++i) {
            if (!events[i].active) { slot = i; break; }
        }
        if (slot < 0) return false;
        events[slot] = Event{priority, next_id++, -1, true};
        ++live_count;
        insert_slot(slot);
        if (live_count > 2 * bucket_count) resize(bucket_count * 2);
        return true;
    }

    bool dequeue(Event& result) {
        if (live_count == 0) return false;
        int bucket = last_bucket;
        for (;;) {
            const int slot = heads[bucket];
            if (slot >= 0 && events[slot].priority * top_den < top_num) {
                result = events[slot];
                heads[bucket] = events[slot].next;
                events[slot].active = false;
                --live_count;
                last_bucket = bucket;
                last_priority = result.priority;
                if (live_count < bucket_count / 2 - 2 && bucket_count > 2) {
                    resize(bucket_count / 2);
                }
                return true;
            }
            bucket = (bucket + 1) % bucket_count;
            top_num += 2 * width_num;
            if (bucket == last_bucket) {
                int minimum = -1;
                for (int i = 0; i < bucket_count; ++i) {
                    const int head = heads[i];
                    if (head >= 0 && (minimum < 0 || less(events[head], events[minimum]))) {
                        minimum = head;
                    }
                }
                if (minimum < 0) return false;
                last_priority = events[minimum].priority;
                reset_cursor(last_priority);
                bucket = last_bucket;
            }
        }
    }
};

void put_i64(std::uint8_t* output, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[word * 8 + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
}
} // namespace

extern "C" std::int64_t calendar_queue(const std::int64_t* input, std::size_t length,
        std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kMaxInput) return -1;
    const auto operation_count = input[0];
    if (operation_count < 0 || operation_count > kMaxOperations
            || length != std::size_t(1 + 2 * operation_count)) return -1;

    Calendar queue;
    std::array<std::int64_t, 2 * kMaxOperations> trace{};
    int dequeue_count = 0;
    for (std::int64_t step = 0; step < operation_count; ++step) {
        const auto opcode = input[1 + 2 * step];
        const auto argument = input[2 + 2 * step];
        if (opcode == 1) {
            if (!queue.enqueue(argument)) return -1;
        } else if (opcode == 2) {
            if (argument != 0) return -1;
            Event event;
            if (!queue.dequeue(event)) return -1;
            trace[2 * dequeue_count] = event.id;
            trace[2 * dequeue_count + 1] = event.priority;
            ++dequeue_count;
        } else {
            return -1;
        }
    }

    const std::size_t bytes = std::size_t(1 + 2 * dequeue_count) * 8;
    if (output == nullptr || capacity < bytes) return -2;
    put_i64(output, 0, dequeue_count);
    for (int i = 0; i < 2 * dequeue_count; ++i) put_i64(output, i + 1, trace[i]);
    return static_cast<std::int64_t>(bytes);
}
