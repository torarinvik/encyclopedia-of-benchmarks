const MAX_LEVEL: i64 = 4;
const MAX_TICKS: i64 = 40;
const MAX_VILLAGES: usize = 85;
const MAX_PATIENTS: usize = MAX_VILLAGES * 40;
const WAITING: usize = 0;
const ASSESSING: usize = 1;
const INSIDE: usize = 2;
const UP: usize = 3;
const IA: i64 = 16807;
const IM: i64 = 2147483647;
const IQ: i64 = 127773;
const IR: i64 = 2836;
const MASK: i64 = 123459876;

const Patient = struct {
    next: i32 = -1,
    previous: i32 = -1,
    time_left: i32 = 0,
    elapsed: i32 = 0,
    hospital_visits: i32 = 0,
};

const Village = struct {
    label: i32 = 0,
    level: i32 = 0,
    free_personnel: i32 = 0,
    seed: i64 = 0,
    head: [4]i32 = .{-1, -1, -1, -1},
    tail: [4]i32 = .{-1, -1, -1, -1},
};

fn queuePush(village: *Village, queue: usize, patient_id: usize,
             patients: *[MAX_PATIENTS]Patient) void {
    const id: i32 = @intCast(patient_id);
    village.head[queue] = if (village.tail[queue] < 0) id else village.head[queue];
    if (village.tail[queue] >= 0) patients[@intCast(village.tail[queue])].next = id;
    patients[patient_id].previous = village.tail[queue];
    patients[patient_id].next = -1;
    village.tail[queue] = id;
}

fn queueRemove(village: *Village, queue: usize, patient_id: usize,
               patients: *[MAX_PATIENTS]Patient) void {
    const previous = patients[patient_id].previous;
    const next = patients[patient_id].next;
    if (previous >= 0) patients[@intCast(previous)].next = next else village.head[queue] = next;
    if (next >= 0) patients[@intCast(next)].previous = previous else village.tail[queue] = previous;
    patients[patient_id].next = -1;
    patients[patient_id].previous = -1;
}

fn healthRandom(village: *Village) f32 {
    var state = village.seed ^ MASK;
    const quotient = @divTrunc(state, IQ);
    state = IA * (state - quotient * IQ) - IR * quotient;
    state ^= MASK;
    if (state < 0) state += IM;
    const value: f32 = @floatCast((1.0 / @as(f64, @floatFromInt(IM))) * @as(f64, @floatFromInt(state)));
    village.seed = @intFromFloat(value * @as(f32, @floatFromInt(IM)));
    return value;
}

fn admitPatient(village: *Village, patient_id: usize, patients: *[MAX_PATIENTS]Patient) void {
    patients[patient_id].hospital_visits += 1;
    if (village.free_personnel > 0) {
        village.free_personnel -= 1;
        patients[patient_id].time_left = 3;
        patients[patient_id].elapsed += 3;
        queuePush(village, ASSESSING, patient_id, patients);
    } else {
        queuePush(village, WAITING, patient_id, patients);
    }
}

fn buildPostorder(label: usize, village_count: usize, order: *[MAX_VILLAGES]usize,
                  order_length: *usize) void {
    var offset: usize = 4;
    while (offset >= 1) : (offset -= 1) {
        const child = label * 4 + offset;
        if (child < village_count) buildPostorder(child, village_count, order, order_length);
    }
    order[order_length.*] = label;
    order_length.* += 1;
}

fn simulateVillage(label: usize, village_count: usize,
                   villages: *[MAX_VILLAGES]Village,
                   patients: *[MAX_PATIENTS]Patient,
                   patient_count: *usize, discharged: *i64) void {
    var offset: usize = 4;
    while (offset >= 1) : (offset -= 1) {
        const child_label = label * 4 + offset;
        if (child_label >= village_count) continue;
        var patient_id = villages[child_label].head[UP];
        while (patient_id >= 0) {
            const id: usize = @intCast(patient_id);
            const next_id = patients[id].next;
            queueRemove(&villages[child_label], UP, id, patients);
            admitPatient(&villages[label], id, patients);
            patient_id = next_id;
        }
    }

    var patient_id = villages[label].head[INSIDE];
    while (patient_id >= 0) {
        const id: usize = @intCast(patient_id);
        const next_id = patients[id].next;
        patients[id].time_left -= 1;
        if (patients[id].time_left == 0) {
            villages[label].free_personnel += 1;
            queueRemove(&villages[label], INSIDE, id, patients);
            discharged.* += 1;
        }
        patient_id = next_id;
    }

    patient_id = villages[label].head[ASSESSING];
    while (patient_id >= 0) {
        const id: usize = @intCast(patient_id);
        const next_id = patients[id].next;
        patients[id].time_left -= 1;
        if (patients[id].time_left == 0) {
            const random_value = healthRandom(&villages[label]);
            queueRemove(&villages[label], ASSESSING, id, patients);
            if (@as(f64, random_value) > 0.1 or villages[label].label == 0) {
                patients[id].time_left = 10;
                patients[id].elapsed += 10;
                queuePush(&villages[label], INSIDE, id, patients);
            } else {
                villages[label].free_personnel += 1;
                queuePush(&villages[label], UP, id, patients);
            }
        }
        patient_id = next_id;
    }

    patient_id = villages[label].head[WAITING];
    while (patient_id >= 0) {
        const id: usize = @intCast(patient_id);
        const next_id = patients[id].next;
        if (villages[label].free_personnel > 0) {
            villages[label].free_personnel -= 1;
            patients[id].time_left = 3;
            patients[id].elapsed += 3;
            queueRemove(&villages[label], WAITING, id, patients);
            queuePush(&villages[label], ASSESSING, id, patients);
        } else {
            patients[id].elapsed += 1;
        }
        patient_id = next_id;
    }

    if (@as(f64, healthRandom(&villages[label])) > 0.666) {
        const new_patient = patient_count.*;
        patient_count.* += 1;
        patients[new_patient] = .{};
        admitPatient(&villages[label], new_patient, patients);
    }
}

export fn olden_health(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 3) return -1;
    const values = input.?;
    const level = values[0];
    const ticks = values[1];
    const seed = values[2];
    if (level < 1 or level > MAX_LEVEL or ticks < 0 or ticks > MAX_TICKS or seed != 1) return -1;

    var village_count: usize = 0;
    var layer_size: usize = 1;
    var depth: i64 = 0;
    while (depth < level) : (depth += 1) {
        village_count += layer_size;
        layer_size *= 4;
    }
    var villages: [MAX_VILLAGES]Village = undefined;
    for (0..village_count) |label| {
        villages[label] = .{};
        villages[label].label = @intCast(label);
        villages[label].level = if (label == 0) @intCast(level) else villages[(label - 1) / 4].level - 1;
        villages[label].free_personnel = @as(i32, 1) << @intCast(villages[label].level - 1);
        villages[label].seed = @as(i64, @intCast(label)) * (IQ + seed);
    }
    var order: [MAX_VILLAGES]usize = undefined;
    var order_length: usize = 0;
    buildPostorder(0, village_count, &order, &order_length);
    var patients: [MAX_PATIENTS]Patient = undefined;
    var patient_count: usize = 0;
    var discharged: i64 = 0;
    var tick: i64 = 0;
    while (tick < ticks) : (tick += 1) {
        for (0..order_length) |index| {
            simulateVillage(order[index], village_count, &villages, &patients, &patient_count, &discharged);
        }
    }
    return discharged;
}
