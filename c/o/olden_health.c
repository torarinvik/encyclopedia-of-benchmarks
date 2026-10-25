#include <stddef.h>
#include <stdint.h>

enum { HEALTH_MAX_LEVEL = 4, HEALTH_MAX_TICKS = 40, HEALTH_MAX_VILLAGES = 85,
       HEALTH_MAX_PATIENTS = HEALTH_MAX_VILLAGES * HEALTH_MAX_TICKS,
       HEALTH_QUEUE_COUNT = 4 };
enum { HEALTH_WAITING = 0, HEALTH_ASSESSING = 1, HEALTH_INSIDE = 2, HEALTH_UP = 3 };
enum { HEALTH_IA = 16807, HEALTH_IM = 2147483647, HEALTH_IQ = 127773,
       HEALTH_IR = 2836, HEALTH_MASK = 123459876 };

typedef struct {
    int next;
    int previous;
    int time_left;
    int elapsed;
    int hospital_visits;
} HealthPatient;

typedef struct {
    int label;
    int level;
    int free_personnel;
    int64_t seed;
    int head[HEALTH_QUEUE_COUNT];
    int tail[HEALTH_QUEUE_COUNT];
} HealthVillage;

static void queue_push(HealthVillage *village, int queue, int patient_id,
                       HealthPatient patients[HEALTH_MAX_PATIENTS]) {
    patients[patient_id].previous = village->tail[queue];
    patients[patient_id].next = -1;
    if (village->tail[queue] >= 0)
        patients[village->tail[queue]].next = patient_id;
    else
        village->head[queue] = patient_id;
    village->tail[queue] = patient_id;
}

static void queue_remove(HealthVillage *village, int queue, int patient_id,
                         HealthPatient patients[HEALTH_MAX_PATIENTS]) {
    int previous = patients[patient_id].previous;
    int next = patients[patient_id].next;
    if (previous >= 0) patients[previous].next = next;
    else village->head[queue] = next;
    if (next >= 0) patients[next].previous = previous;
    else village->tail[queue] = previous;
    patients[patient_id].next = -1;
    patients[patient_id].previous = -1;
}

static float health_random(HealthVillage *village) {
    int64_t state = village->seed ^ HEALTH_MASK;
    int64_t quotient = state / HEALTH_IQ;
    state = HEALTH_IA * (state - quotient * HEALTH_IQ) - HEALTH_IR * quotient;
    state ^= HEALTH_MASK;
    if (state < 0) state += HEALTH_IM;
    float value = (float)((1.0 / HEALTH_IM) * (double)state);
    village->seed = (int64_t)(value * (float)HEALTH_IM);
    return value;
}

static void admit_patient(HealthVillage *village, int patient_id,
                          HealthPatient patients[HEALTH_MAX_PATIENTS]) {
    HealthPatient *patient = &patients[patient_id];
    patient->hospital_visits += 1;
    if (village->free_personnel > 0) {
        village->free_personnel -= 1;
        patient->time_left = 3;
        patient->elapsed += 3;
        queue_push(village, HEALTH_ASSESSING, patient_id, patients);
    } else {
        queue_push(village, HEALTH_WAITING, patient_id, patients);
    }
}

static void build_postorder(int label, int village_count, int order[HEALTH_MAX_VILLAGES],
                            int *order_length) {
    for (int offset = 4; offset >= 1; --offset) {
        int child = label * 4 + offset;
        if (child < village_count)
            build_postorder(child, village_count, order, order_length);
    }
    order[*order_length] = label;
    *order_length += 1;
}

static void simulate_village(int label, int village_count,
                             HealthVillage villages[HEALTH_MAX_VILLAGES],
                             HealthPatient patients[HEALTH_MAX_PATIENTS],
                             int *patient_count, int *discharged) {
    HealthVillage *village = &villages[label];

    for (int offset = 4; offset >= 1; --offset) {
        int child_label = label * 4 + offset;
        if (child_label >= village_count) continue;
        HealthVillage *child = &villages[child_label];
        int patient_id = child->head[HEALTH_UP];
        while (patient_id >= 0) {
            int next_id = patients[patient_id].next;
            queue_remove(child, HEALTH_UP, patient_id, patients);
            admit_patient(village, patient_id, patients);
            patient_id = next_id;
        }
    }

    int patient_id = village->head[HEALTH_INSIDE];
    while (patient_id >= 0) {
        int next_id = patients[patient_id].next;
        patients[patient_id].time_left -= 1;
        if (patients[patient_id].time_left == 0) {
            village->free_personnel += 1;
            queue_remove(village, HEALTH_INSIDE, patient_id, patients);
            *discharged += 1;
        }
        patient_id = next_id;
    }

    patient_id = village->head[HEALTH_ASSESSING];
    while (patient_id >= 0) {
        int next_id = patients[patient_id].next;
        patients[patient_id].time_left -= 1;
        if (patients[patient_id].time_left == 0) {
            float random_value = health_random(village);
            queue_remove(village, HEALTH_ASSESSING, patient_id, patients);
            if (random_value > 0.1 || village->label == 0) {
                patients[patient_id].time_left = 10;
                patients[patient_id].elapsed += 10;
                queue_push(village, HEALTH_INSIDE, patient_id, patients);
            } else {
                village->free_personnel += 1;
                queue_push(village, HEALTH_UP, patient_id, patients);
            }
        }
        patient_id = next_id;
    }

    patient_id = village->head[HEALTH_WAITING];
    while (patient_id >= 0) {
        int next_id = patients[patient_id].next;
        if (village->free_personnel > 0) {
            village->free_personnel -= 1;
            patients[patient_id].time_left = 3;
            patients[patient_id].elapsed += 3;
            queue_remove(village, HEALTH_WAITING, patient_id, patients);
            queue_push(village, HEALTH_ASSESSING, patient_id, patients);
        } else {
            patients[patient_id].elapsed += 1;
        }
        patient_id = next_id;
    }

    if (health_random(village) > 0.666) {
        int new_patient = *patient_count;
        *patient_count += 1;
        patients[new_patient] = (HealthPatient){0, -1, 0, 0, 0};
        admit_patient(village, new_patient, patients);
    }
}

int64_t olden_health(const int64_t *input, size_t length) {
    if (input == NULL || length != 3 || input[0] < 1 || input[0] > HEALTH_MAX_LEVEL ||
        input[1] < 0 || input[1] > HEALTH_MAX_TICKS || input[2] != 1) return -1;

    int village_count = 0;
    int layer_size = 1;
    for (int depth = 0; depth < (int)input[0]; ++depth) {
        village_count += layer_size;
        layer_size *= 4;
    }

    HealthVillage villages[HEALTH_MAX_VILLAGES] = {0};
    for (int label = 0; label < village_count; ++label) {
        HealthVillage *village = &villages[label];
        village->label = label;
        village->level = label == 0 ? (int)input[0] : villages[(label - 1) / 4].level - 1;
        village->free_personnel = 1 << (village->level - 1);
        village->seed = (int64_t)label * (HEALTH_IQ + input[2]);
        for (int queue = 0; queue < HEALTH_QUEUE_COUNT; ++queue) {
            village->head[queue] = -1;
            village->tail[queue] = -1;
        }
    }

    int order[HEALTH_MAX_VILLAGES];
    int order_length = 0;
    build_postorder(0, village_count, order, &order_length);
    HealthPatient patients[HEALTH_MAX_PATIENTS] = {0};
    int patient_count = 0;
    int discharged = 0;
    for (int tick = 0; tick < (int)input[1]; ++tick) {
        for (int index = 0; index < order_length; ++index)
            simulate_village(order[index], village_count, villages, patients,
                             &patient_count, &discharged);
    }
    return discharged;
}
