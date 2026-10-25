#include <stddef.h>
#include <stdint.h>

#define MAX_ITERATIONS INT64_C(1000000)
#define INVALID_RESULT INT64_C(-1)
#define I_IDLE 1
#define I_WORK 2
#define I_HANDLERA 3
#define I_HANDLERB 4
#define I_DEVA 5
#define I_DEVB 6
#define K_DEV 1000
#define K_WORK 1001
#define PKTBIT 1
#define WAITBIT 2
#define HOLDBIT 4
#define S_RUN 0
#define S_RUNPKT 1
#define S_WAIT 2
#define S_WAITPKT 3
#define S_HOLD 4
#define S_HOLDPKT 5
#define S_HOLDWAIT 6
#define S_HOLDWAITPKT 7
#define BUFSIZE 3
#define MAXINT 32767

typedef struct { int link, id, kind, a1, a2[4]; } Packet;
typedef struct { int link, id, priority, queue, state; int64_t v1, v2; } Task;
static Packet packets[9];
static Task tasks[7];
static int packet_used, tasklist, current, taskid, qpktcount, holdcount;
static int64_t v1, v2;

static int make_packet(int link, int id, int kind) {
    int index = ++packet_used;
    packets[index] = (Packet){link, id, kind, 0, {0, 0, 0, 0}};
    return index;
}

static void make_task(int id, int priority, int queue, int state, int64_t a, int64_t b) {
    tasks[id] = (Task){tasklist, id, priority, queue, state, a, b};
    tasklist = id;
}

static void append_packet(int packet, int *head) {
    int tail;
    packets[packet].link = 0;
    if (*head == 0) { *head = packet; return; }
    tail = *head;
    while (packets[tail].link != 0) tail = packets[tail].link;
    packets[tail].link = packet;
}

static int queue_packet(int packet) {
    int destination = packets[packet].id;
    Task *target = &tasks[destination];
    ++qpktcount;
    packets[packet].link = 0;
    packets[packet].id = taskid;
    if (target->queue == 0) {
        target->queue = packet;
        target->state |= PKTBIT;
        if (target->priority > tasks[taskid].priority) return destination;
    } else {
        append_packet(packet, &target->queue);
    }
    return current;
}

static int release_task(int destination) {
    Task *target = &tasks[destination];
    target->state &= ~HOLDBIT;
    return target->priority > tasks[taskid].priority ? destination : current;
}

static int wait_task(void) { tasks[taskid].state |= WAITBIT; return taskid; }
static int hold_task(void) {
    ++holdcount;
    tasks[taskid].state |= HOLDBIT;
    return tasks[taskid].link;
}

static int run_task(int packet) {
    if (taskid == I_IDLE) {
        --v2;
        if (v2 == 0) return hold_task();
        if ((v1 & 1) == 0) { v1 = (v1 >> 1) & MAXINT; return release_task(I_DEVA); }
        v1 = ((v1 >> 1) & MAXINT) ^ 0xD008;
        return release_task(I_DEVB);
    }
    if (taskid == I_WORK) {
        int index;
        if (packet == 0) return wait_task();
        v1 = I_HANDLERA + I_HANDLERB - v1;
        packets[packet].id = (int)v1;
        packets[packet].a1 = 0;
        for (index = 0; index <= BUFSIZE; ++index) {
            static const char alphabet[] = "0ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            ++v2;
            if (v2 > 26) v2 = 1;
            packets[packet].a2[index] = alphabet[v2];
        }
        return queue_packet(packet);
    }
    if (taskid == I_HANDLERA || taskid == I_HANDLERB) {
        if (packet != 0) {
            if (packets[packet].kind == K_WORK) {
                int head = (int)v1;
                append_packet(packet, &head);
                v1 = head;
            } else {
                int head = (int)v2;
                append_packet(packet, &head);
                v2 = head;
            }
        }
        if (v1 != 0) {
            int work_packet = (int)v1;
            int count = packets[work_packet].a1;
            if (count > BUFSIZE) {
                v1 = packets[work_packet].link;
                return queue_packet(work_packet);
            }
            if (v2 != 0) {
                int device_packet = (int)v2;
                v2 = packets[device_packet].link;
                packets[device_packet].a1 = packets[work_packet].a2[count];
                packets[work_packet].a1 = count + 1;
                return queue_packet(device_packet);
            }
        }
        return wait_task();
    }
    if (packet == 0) {
        if (v1 == 0) return wait_task();
        packet = (int)v1;
        v1 = 0;
        return queue_packet(packet);
    }
    v1 = packet;
    return hold_task();
}

static int schedule(void) {
    while (current != 0) {
        int packet = 0;
        Task *task = &tasks[current];
        if (task->state == S_WAITPKT) {
            packet = task->queue;
            task->queue = packets[packet].link;
            task->state = task->queue == 0 ? S_RUN : S_RUNPKT;
        }
        if (task->state == S_RUN || task->state == S_RUNPKT) {
            taskid = task->id;
            v1 = task->v1; v2 = task->v2;
            current = run_task(packet);
            task->v1 = v1; task->v2 = v2;
        } else if (task->state == S_WAIT || task->state == S_HOLD ||
                   task->state == S_HOLDPKT || task->state == S_HOLDWAIT ||
                   task->state == S_HOLDWAITPKT) {
            current = task->link;
        } else return INVALID_RESULT;
    }
    return 0;
}

int64_t richards_benchmark(const int64_t *input, size_t length) {
    if (input == NULL || length != 1 || input[0] < 1 || input[0] > MAX_ITERATIONS)
        return INVALID_RESULT;
    for (int i = 0; i < 9; ++i) packets[i] = (Packet){0};
    for (int i = 0; i < 7; ++i) tasks[i] = (Task){0};
    packet_used = tasklist = current = taskid = qpktcount = holdcount = 0;
    v1 = v2 = 0;

    int work = make_packet(0, 0, K_WORK);
    work = make_packet(work, 0, K_WORK);
    make_task(I_IDLE, 0, 0, S_RUN, 1, input[0]);
    make_task(I_WORK, 1000, work, S_WAITPKT, I_HANDLERA, 0);
    int handler_a = make_packet(0, I_DEVA, K_DEV);
    handler_a = make_packet(handler_a, I_DEVA, K_DEV);
    handler_a = make_packet(handler_a, I_DEVA, K_DEV);
    make_task(I_HANDLERA, 2000, handler_a, S_WAITPKT, 0, 0);
    int handler_b = make_packet(0, I_DEVB, K_DEV);
    handler_b = make_packet(handler_b, I_DEVB, K_DEV);
    handler_b = make_packet(handler_b, I_DEVB, K_DEV);
    make_task(I_HANDLERB, 3000, handler_b, S_WAITPKT, 0, 0);
    make_task(I_DEVA, 4000, 0, S_WAIT, 0, 0);
    make_task(I_DEVB, 5000, 0, S_WAIT, 0, 0);
    current = tasklist;
    if (schedule() != 0) return INVALID_RESULT;
    return (int64_t)qpktcount * INT64_C(2147483648) + holdcount;
}
