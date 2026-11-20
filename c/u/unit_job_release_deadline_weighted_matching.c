#include <stddef.h>
#include <stdint.h>

/* Unit jobs are considered by weight; alternating paths may move earlier jobs. */
typedef struct {
    int release[32], deadline[32], slot_job[32];
    unsigned char visited[32];
} Schedule;

static int assign_job(Schedule *schedule, int job) {
    for (int slot = schedule->release[job]; slot <= schedule->deadline[job]; ++slot) {
        if (schedule->visited[slot]) continue;
        schedule->visited[slot] = 1;
        int previous = schedule->slot_job[slot];
        if (previous == -1 || assign_job(schedule, previous)) {
            schedule->slot_job[slot] = job;
            return 1;
        }
    }
    return 0;
}

int64_t unit_job_release_deadline_weighted_matching(const int64_t *input, size_t length) {
    if (!input || length < 1 || length > 98 || input[0] < 0 || input[0] > 32) return -1;
    int n = (int)input[0];
    if (length != (size_t)(1 + 3 * n)) return -1;
    Schedule schedule = {0};
    int order[32];
    int64_t weight[32];
    for (int slot = 0; slot < 32; ++slot) schedule.slot_job[slot] = -1;
    for (int i = 0; i < n; ++i) {
        int64_t release = input[1 + 3*i], deadline = input[2 + 3*i], w = input[3 + 3*i];
        if (release < 0 || deadline < release || deadline >= 32 || w < 0 || w > 1000000) return -1;
        schedule.release[i] = (int)release;
        schedule.deadline[i] = (int)deadline;
        weight[i] = w;
        int j = i;
        while (j > 0 && weight[order[j-1]] < w) { order[j] = order[j-1]; --j; }
        order[j] = i;
    }
    int64_t total = 0;
    for (int i = 0; i < n; ++i) {
        for (int slot = 0; slot < 32; ++slot) schedule.visited[slot] = 0;
        int job = order[i];
        if (assign_job(&schedule, job)) total += weight[job];
    }
    return total;
}
