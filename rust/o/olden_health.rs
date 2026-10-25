const MAX_LEVEL: i64 = 4;
const MAX_TICKS: i64 = 40;
const MAX_VILLAGES: usize = 85;
const MAX_PATIENTS: usize = MAX_VILLAGES * MAX_TICKS as usize;
const WAITING: usize = 0;
const ASSESSING: usize = 1;
const INSIDE: usize = 2;
const UP: usize = 3;
const IA: i64 = 16807;
const IM: i64 = 2147483647;
const IQ: i64 = 127773;
const IR: i64 = 2836;
const MASK: i64 = 123459876;

#[derive(Clone, Copy, Default)]
struct Patient {
    next: i32,
    previous: i32,
    time_left: i32,
    elapsed: i32,
    hospital_visits: i32,
}

#[derive(Clone, Copy)]
struct Village {
    label: i32,
    level: i32,
    free_personnel: i32,
    seed: i64,
    head: [i32; 4],
    tail: [i32; 4],
}

fn queue_push(village: &mut Village, queue: usize, patient_id: usize,
              patients: &mut [Patient; MAX_PATIENTS]) {
    let id = patient_id as i32;
    patients[patient_id].previous = village.tail[queue];
    patients[patient_id].next = -1;
    if village.tail[queue] >= 0 {
        patients[village.tail[queue] as usize].next = id;
    } else {
        village.head[queue] = id;
    }
    village.tail[queue] = id;
}

fn queue_remove(village: &mut Village, queue: usize, patient_id: usize,
                patients: &mut [Patient; MAX_PATIENTS]) {
    let previous = patients[patient_id].previous;
    let next = patients[patient_id].next;
    if previous >= 0 {
        patients[previous as usize].next = next;
    } else {
        village.head[queue] = next;
    }
    if next >= 0 {
        patients[next as usize].previous = previous;
    } else {
        village.tail[queue] = previous;
    }
    patients[patient_id].next = -1;
    patients[patient_id].previous = -1;
}

fn health_random(village: &mut Village) -> f32 {
    let mut state = village.seed ^ MASK;
    let quotient = state / IQ;
    state = IA * (state - quotient * IQ) - IR * quotient;
    state ^= MASK;
    if state < 0 { state += IM; }
    let value = ((1.0 / IM as f64) * state as f64) as f32;
    village.seed = (value * IM as f32) as i64;
    value
}

fn admit_patient(village: &mut Village, patient_id: usize,
                 patients: &mut [Patient; MAX_PATIENTS]) {
    patients[patient_id].hospital_visits += 1;
    if village.free_personnel > 0 {
        village.free_personnel -= 1;
        patients[patient_id].time_left = 3;
        patients[patient_id].elapsed += 3;
        queue_push(village, ASSESSING, patient_id, patients);
    } else {
        queue_push(village, WAITING, patient_id, patients);
    }
}

fn build_postorder(label: usize, village_count: usize, order: &mut [usize; MAX_VILLAGES],
                   order_length: &mut usize) {
    for offset in (1..=4).rev() {
        let child = label * 4 + offset;
        if child < village_count { build_postorder(child, village_count, order, order_length); }
    }
    order[*order_length] = label;
    *order_length += 1;
}

fn simulate_village(label: usize, village_count: usize,
                    villages: &mut [Village; MAX_VILLAGES],
                    patients: &mut [Patient; MAX_PATIENTS],
                    patient_count: &mut usize, discharged: &mut i64) {
    for offset in (1..=4).rev() {
        let child_label = label * 4 + offset;
        if child_label >= village_count { continue; }
        let mut patient_id = villages[child_label].head[UP];
        while patient_id >= 0 {
            let id = patient_id as usize;
            let next_id = patients[id].next;
            queue_remove(&mut villages[child_label], UP, id, patients);
            admit_patient(&mut villages[label], id, patients);
            patient_id = next_id;
        }
    }

    let mut patient_id = villages[label].head[INSIDE];
    while patient_id >= 0 {
        let id = patient_id as usize;
        let next_id = patients[id].next;
        patients[id].time_left -= 1;
        if patients[id].time_left == 0 {
            villages[label].free_personnel += 1;
            queue_remove(&mut villages[label], INSIDE, id, patients);
            *discharged += 1;
        }
        patient_id = next_id;
    }

    patient_id = villages[label].head[ASSESSING];
    while patient_id >= 0 {
        let id = patient_id as usize;
        let next_id = patients[id].next;
        patients[id].time_left -= 1;
        if patients[id].time_left == 0 {
            let random_value = health_random(&mut villages[label]);
            queue_remove(&mut villages[label], ASSESSING, id, patients);
            if random_value as f64 > 0.1 || villages[label].label == 0 {
                patients[id].time_left = 10;
                patients[id].elapsed += 10;
                queue_push(&mut villages[label], INSIDE, id, patients);
            } else {
                villages[label].free_personnel += 1;
                queue_push(&mut villages[label], UP, id, patients);
            }
        }
        patient_id = next_id;
    }

    patient_id = villages[label].head[WAITING];
    while patient_id >= 0 {
        let id = patient_id as usize;
        let next_id = patients[id].next;
        if villages[label].free_personnel > 0 {
            villages[label].free_personnel -= 1;
            patients[id].time_left = 3;
            patients[id].elapsed += 3;
            queue_remove(&mut villages[label], WAITING, id, patients);
            queue_push(&mut villages[label], ASSESSING, id, patients);
        } else {
            patients[id].elapsed += 1;
        }
        patient_id = next_id;
    }

    if health_random(&mut villages[label]) as f64 > 0.666 {
        let new_patient = *patient_count;
        *patient_count += 1;
        patients[new_patient] = Patient { next: -1, previous: -1, time_left: 0,
            elapsed: 0, hospital_visits: 0 };
        admit_patient(&mut villages[label], new_patient, patients);
    }
}

#[no_mangle]
pub unsafe extern "C" fn olden_health(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let level = *input;
    let ticks = *input.add(1);
    let seed = *input.add(2);
    if !(1..=MAX_LEVEL).contains(&level) || !(0..=MAX_TICKS).contains(&ticks) || seed != 1 {
        return -1;
    }
    let mut village_count = 0usize;
    let mut layer_size = 1usize;
    for _ in 0..level { village_count += layer_size; layer_size *= 4; }
    let mut villages = [Village { label: 0, level: 0, free_personnel: 0, seed: 0,
        head: [-1; 4], tail: [-1; 4] }; MAX_VILLAGES];
    for label in 0..village_count {
        villages[label].label = label as i32;
        villages[label].level = if label == 0 { level as i32 } else { villages[(label - 1) / 4].level - 1 };
        villages[label].free_personnel = 1 << (villages[label].level - 1);
        villages[label].seed = label as i64 * (IQ + seed);
        villages[label].head = [-1; 4];
        villages[label].tail = [-1; 4];
    }
    let mut order = [0usize; MAX_VILLAGES];
    let mut order_length = 0usize;
    build_postorder(0, village_count, &mut order, &mut order_length);
    let mut patients = [Patient::default(); MAX_PATIENTS];
    let mut patient_count = 0usize;
    let mut discharged = 0i64;
    for _ in 0..ticks {
        for index in 0..order_length {
            simulate_village(order[index], village_count, &mut villages, &mut patients,
                &mut patient_count, &mut discharged);
        }
    }
    discharged
}
