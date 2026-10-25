#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_level = 4;
constexpr int max_ticks = 40;
constexpr int max_villages = 85;
constexpr int max_patients = max_villages * max_ticks;
constexpr int queue_count = 4;
enum Queue { waiting = 0, assessing = 1, inside = 2, up = 3 };
constexpr std::int64_t ia = 16807, im = 2147483647, iq = 127773, ir = 2836, mask = 123459876;

struct Patient {
    int next;
    int previous;
    int time_left;
    int elapsed;
    int hospital_visits;
};

struct Village {
    int label;
    int level;
    int free_personnel;
    std::int64_t seed;
    int head[queue_count];
    int tail[queue_count];
};

void queue_push(Village* village, int queue, int patient_id, Patient* patients) {
    patients[patient_id].previous = village->tail[queue];
    patients[patient_id].next = -1;
    if (village->tail[queue] >= 0) patients[village->tail[queue]].next = patient_id;
    else village->head[queue] = patient_id;
    village->tail[queue] = patient_id;
}

void queue_remove(Village* village, int queue, int patient_id, Patient* patients) {
    const int previous = patients[patient_id].previous;
    const int next = patients[patient_id].next;
    if (previous >= 0) patients[previous].next = next;
    else village->head[queue] = next;
    if (next >= 0) patients[next].previous = previous;
    else village->tail[queue] = previous;
    patients[patient_id].next = -1;
    patients[patient_id].previous = -1;
}

float health_random(Village* village) {
    std::int64_t state = village->seed ^ mask;
    const std::int64_t quotient = state / iq;
    state = ia * (state - quotient * iq) - ir * quotient;
    state ^= mask;
    if (state < 0) state += im;
    const float value = static_cast<float>((1.0 / static_cast<double>(im)) * static_cast<double>(state));
    village->seed = static_cast<std::int64_t>(value * static_cast<float>(im));
    return value;
}

void admit_patient(Village* village, int patient_id, Patient* patients) {
    Patient* patient = &patients[patient_id];
    patient->hospital_visits += 1;
    if (village->free_personnel > 0) {
        village->free_personnel -= 1;
        patient->time_left = 3;
        patient->elapsed += 3;
        queue_push(village, assessing, patient_id, patients);
    } else {
        queue_push(village, waiting, patient_id, patients);
    }
}

void build_postorder(int label, int village_count, int* order, int* order_length) {
    for (int offset = 4; offset >= 1; --offset) {
        const int child = label * 4 + offset;
        if (child < village_count) build_postorder(child, village_count, order, order_length);
    }
    order[(*order_length)++] = label;
}

void simulate_village(int label, int village_count, Village* villages, Patient* patients,
                      int* patient_count, int* discharged) {
    Village* village = &villages[label];
    for (int offset = 4; offset >= 1; --offset) {
        const int child_label = label * 4 + offset;
        if (child_label >= village_count) continue;
        Village* child = &villages[child_label];
        int patient_id = child->head[up];
        while (patient_id >= 0) {
            const int next_id = patients[patient_id].next;
            queue_remove(child, up, patient_id, patients);
            admit_patient(village, patient_id, patients);
            patient_id = next_id;
        }
    }

    int patient_id = village->head[inside];
    while (patient_id >= 0) {
        const int next_id = patients[patient_id].next;
        patients[patient_id].time_left -= 1;
        if (patients[patient_id].time_left == 0) {
            village->free_personnel += 1;
            queue_remove(village, inside, patient_id, patients);
            *discharged += 1;
        }
        patient_id = next_id;
    }

    patient_id = village->head[assessing];
    while (patient_id >= 0) {
        const int next_id = patients[patient_id].next;
        patients[patient_id].time_left -= 1;
        if (patients[patient_id].time_left == 0) {
            const float random_value = health_random(village);
            queue_remove(village, assessing, patient_id, patients);
            if (random_value > 0.1 || village->label == 0) {
                patients[patient_id].time_left = 10;
                patients[patient_id].elapsed += 10;
                queue_push(village, inside, patient_id, patients);
            } else {
                village->free_personnel += 1;
                queue_push(village, up, patient_id, patients);
            }
        }
        patient_id = next_id;
    }

    patient_id = village->head[waiting];
    while (patient_id >= 0) {
        const int next_id = patients[patient_id].next;
        if (village->free_personnel > 0) {
            village->free_personnel -= 1;
            patients[patient_id].time_left = 3;
            patients[patient_id].elapsed += 3;
            queue_remove(village, waiting, patient_id, patients);
            queue_push(village, assessing, patient_id, patients);
        } else {
            patients[patient_id].elapsed += 1;
        }
        patient_id = next_id;
    }

    if (health_random(village) > 0.666) {
        const int new_patient = (*patient_count)++;
        patients[new_patient] = Patient{0, -1, 0, 0, 0};
        admit_patient(village, new_patient, patients);
    }
}
}

extern "C" std::int64_t olden_health(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length != 3 || input[0] < 1 || input[0] > max_level ||
        input[1] < 0 || input[1] > max_ticks || input[2] != 1) return -1;
    int village_count = 0, layer_size = 1;
    for (int depth = 0; depth < static_cast<int>(input[0]); ++depth) {
        village_count += layer_size;
        layer_size *= 4;
    }
    Village villages[max_villages]{};
    for (int label = 0; label < village_count; ++label) {
        Village& village = villages[label];
        village.label = label;
        village.level = label == 0 ? static_cast<int>(input[0]) : villages[(label - 1) / 4].level - 1;
        village.free_personnel = 1 << (village.level - 1);
        village.seed = static_cast<std::int64_t>(label) * (iq + input[2]);
        for (int queue = 0; queue < queue_count; ++queue) village.head[queue] = village.tail[queue] = -1;
    }
    int order[max_villages]{};
    int order_length = 0;
    build_postorder(0, village_count, order, &order_length);
    Patient patients[max_patients]{};
    int patient_count = 0, discharged = 0;
    for (int tick = 0; tick < static_cast<int>(input[1]); ++tick)
        for (int index = 0; index < order_length; ++index)
            simulate_village(order[index], village_count, villages, patients, &patient_count, &discharged);
    return discharged;
}
