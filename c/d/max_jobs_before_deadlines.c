#include <stddef.h>
#include <stdint.h>

#define MAX_JOBS 12

typedef struct {
    int64_t deadline;
    int64_t duration;
    int id;
} job;

typedef struct {
    int64_t duration[MAX_JOBS];
    int id[MAX_JOBS];
    size_t size;
} min_heap;

static int comes_before(int64_t left_duration, int left_id,
                        int64_t right_duration, int right_id)
{
    return left_duration < right_duration ||
           (left_duration == right_duration && left_id < right_id);
}

static void heap_push(min_heap *heap, int64_t duration, int id)
{
    size_t index = heap->size++;
    while (index > 0) {
        const size_t parent = (index - 1) / 2;
        if (!comes_before(duration, id, heap->duration[parent], heap->id[parent])) break;
        heap->duration[index] = heap->duration[parent];
        heap->id[index] = heap->id[parent];
        index = parent;
    }
    heap->duration[index] = duration;
    heap->id[index] = id;
}

static void heap_pop(min_heap *heap, int64_t *duration, int *id)
{
    *duration = heap->duration[0];
    *id = heap->id[0];
    --heap->size;
    if (heap->size == 0) return;
    const int64_t last_duration = heap->duration[heap->size];
    const int last_id = heap->id[heap->size];
    size_t index = 0;
    while (2 * index + 1 < heap->size) {
        size_t child = 2 * index + 1;
        if (child + 1 < heap->size &&
            comes_before(heap->duration[child + 1], heap->id[child + 1],
                         heap->duration[child], heap->id[child])) ++child;
        if (!comes_before(heap->duration[child], heap->id[child], last_duration, last_id)) break;
        heap->duration[index] = heap->duration[child];
        heap->id[index] = heap->id[child];
        index = child;
    }
    heap->duration[index] = last_duration;
    heap->id[index] = last_id;
}

int64_t max_jobs_before_deadlines(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > 1 + 2 * MAX_JOBS) return -1;
    const int64_t count_value = input[0];
    if (count_value < 0 || count_value > MAX_JOBS ||
        length != 1 + 2 * (size_t)count_value) return -1;
    const size_t count = (size_t)count_value;
    job jobs[MAX_JOBS];
    for (size_t i = 0; i < count; ++i) {
        const int64_t deadline = input[1 + 2 * i];
        const int64_t duration = input[2 + 2 * i];
        if (deadline < 0 || deadline > 1000 || duration < 1 || duration > 1000) return -1;
        jobs[i] = (job){deadline, duration, (int)i};
    }
    for (size_t i = 1; i < count; ++i) {
        const job item = jobs[i];
        size_t position = i;
        while (position > 0 && jobs[position - 1].deadline > item.deadline) {
            jobs[position] = jobs[position - 1];
            --position;
        }
        jobs[position] = item;
    }
    min_heap heap = {0};
    int64_t completed = 0;
    for (size_t end = count; end > 0; --end) {
        const size_t index = end - 1;
        heap_push(&heap, jobs[index].duration, jobs[index].id);
        const int64_t lower = index == 0 ? 0 : jobs[index - 1].deadline;
        int64_t interval = jobs[index].deadline - lower;
        while (interval > 0 && heap.size > 0) {
            int64_t remaining;
            int id;
            heap_pop(&heap, &remaining, &id);
            if (remaining <= interval) {
                interval -= remaining;
                ++completed;
            } else {
                heap_push(&heap, remaining - interval, id);
                interval = 0;
            }
        }
    }
    return completed;
}
