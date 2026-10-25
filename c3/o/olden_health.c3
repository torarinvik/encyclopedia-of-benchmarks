module olden_health;

const int MAX_LEVEL = 4;
const int MAX_TICKS = 40;
const int MAX_VILLAGES = 85;
const int MAX_PATIENTS = MAX_VILLAGES * MAX_TICKS;
const int QUEUES = 4;
const int WAITING = 0, ASSESSING = 1, INSIDE = 2, UP = 3;
const long IA = 16807, IM = 2147483647, IQ = 127773, IR = 2836, MASK = 123459876;

struct Patient {
    int next;
    int previous;
    int time_left;
    int elapsed;
    int hospital_visits;
}

struct Village {
    int label;
    int level;
    int free_personnel;
    long seed;
    int[QUEUES] head;
    int[QUEUES] tail;
}

fn void queue_push(Village* village, int queue, int patient_id, Patient* patients) {
    patients[patient_id].previous = village.tail[queue];
    patients[patient_id].next = -1;
    if (village.tail[queue] >= 0) patients[village.tail[queue]].next = patient_id;
    else village.head[queue] = patient_id;
    village.tail[queue] = patient_id;
}

fn void queue_remove(Village* village, int queue, int patient_id, Patient* patients) {
    int previous = patients[patient_id].previous;
    int next = patients[patient_id].next;
    if (previous >= 0) patients[previous].next = next;
    else village.head[queue] = next;
    if (next >= 0) patients[next].previous = previous;
    else village.tail[queue] = previous;
    patients[patient_id].next = -1;
    patients[patient_id].previous = -1;
}

fn float health_random(Village* village) {
    long state = village.seed ^ MASK;
    long quotient = state / IQ;
    state = IA * (state - quotient * IQ) - IR * quotient;
    state ^= MASK;
    if (state < 0) state += IM;
    float value = (float)((1.0 / (double)IM) * (double)state);
    village.seed = (long)(value * (float)IM);
    return value;
}

fn void admit_patient(Village* village, int patient_id, Patient* patients) {
    patients[patient_id].hospital_visits += 1;
    if (village.free_personnel > 0) {
        village.free_personnel -= 1;
        patients[patient_id].time_left = 3;
        patients[patient_id].elapsed += 3;
        queue_push(village, ASSESSING, patient_id, patients);
    } else {
        queue_push(village, WAITING, patient_id, patients);
    }
}

fn void build_postorder(int label, int village_count, int* order, int* order_length) {
    for (int offset = 4; offset >= 1; --offset) {
        int child = label * 4 + offset;
        if (child < village_count) build_postorder(child, village_count, order, order_length);
    }
    order[*order_length] = label;
    *order_length += 1;
}

fn void simulate_village(int label, int village_count, Village* villages, Patient* patients,
                         int* patient_count, int* discharged) {
    Village* village = &villages[label];
    for (int offset = 4; offset >= 1; --offset) {
        int child_label = label * 4 + offset;
        if (child_label >= village_count) continue;
        Village* child = &villages[child_label];
        int patient_id = child.head[UP];
        while (patient_id >= 0) {
            int next_id = patients[patient_id].next;
            queue_remove(child, UP, patient_id, patients);
            admit_patient(village, patient_id, patients);
            patient_id = next_id;
        }
    }
    int patient_id = village.head[INSIDE];
    while (patient_id >= 0) {
        int next_id = patients[patient_id].next;
        patients[patient_id].time_left -= 1;
        if (patients[patient_id].time_left == 0) {
            village.free_personnel += 1;
            queue_remove(village, INSIDE, patient_id, patients);
            *discharged += 1;
        }
        patient_id = next_id;
    }
    patient_id = village.head[ASSESSING];
    while (patient_id >= 0) {
        int next_id = patients[patient_id].next;
        patients[patient_id].time_left -= 1;
        if (patients[patient_id].time_left == 0) {
            float random_value = health_random(village);
            queue_remove(village, ASSESSING, patient_id, patients);
            if ((double)random_value > 0.1 || village.label == 0) {
                patients[patient_id].time_left = 10;
                patients[patient_id].elapsed += 10;
                queue_push(village, INSIDE, patient_id, patients);
            } else {
                village.free_personnel += 1;
                queue_push(village, UP, patient_id, patients);
            }
        }
        patient_id = next_id;
    }
    patient_id = village.head[WAITING];
    while (patient_id >= 0) {
        int next_id = patients[patient_id].next;
        if (village.free_personnel > 0) {
            village.free_personnel -= 1;
            patients[patient_id].time_left = 3;
            patients[patient_id].elapsed += 3;
            queue_remove(village, WAITING, patient_id, patients);
            queue_push(village, ASSESSING, patient_id, patients);
        } else {
            patients[patient_id].elapsed += 1;
        }
        patient_id = next_id;
    }
    if ((double)health_random(village) > 0.666) {
        int new_patient = *patient_count;
        *patient_count += 1;
        patients[new_patient].next = -1;
        patients[new_patient].previous = -1;
        patients[new_patient].time_left = 0;
        patients[new_patient].elapsed = 0;
        patients[new_patient].hospital_visits = 0;
        admit_patient(village, new_patient, patients);
    }
}

fn long olden_health(long* input, usz length) @export("olden_health") {
    if (input == null || length != 3 || input[0] < 1 || input[0] > MAX_LEVEL ||
        input[1] < 0 || input[1] > MAX_TICKS || input[2] != 1) return -1;
    int village_count = 0;
    int layer_size = 1;
    for (int depth = 0; depth < (int)input[0]; ++depth) {
        village_count += layer_size;
        layer_size *= 4;
    }
    Village[MAX_VILLAGES] villages = {};
    for (int label = 0; label < village_count; ++label) {
        Village* village = &villages[label];
        village.label = label;
        village.level = label == 0 ? (int)input[0] : villages[(label - 1) / 4].level - 1;
        village.free_personnel = 1 << (village.level - 1);
        village.seed = (long)label * (IQ + input[2]);
        for (int queue = 0; queue < QUEUES; ++queue) {
            village.head[queue] = -1;
            village.tail[queue] = -1;
        }
    }
    int[MAX_VILLAGES] order = {};
    int order_length = 0;
    build_postorder(0, village_count, &order[0], &order_length);
    Patient[MAX_PATIENTS] patients = {};
    int patient_count = 0;
    int discharged = 0;
    for (int tick = 0; tick < (int)input[1]; ++tick)
        for (int index = 0; index < order_length; ++index)
            simulate_village(order[index], village_count, &villages[0], &patients[0],
                             &patient_count, &discharged);
    return (long)discharged;
}
