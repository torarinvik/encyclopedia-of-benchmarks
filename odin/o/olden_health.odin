package olden_health

import "core:c"

MAX_LEVEL :: 4
MAX_TICKS :: 40
MAX_VILLAGES :: 85
MAX_PATIENTS :: MAX_VILLAGES * MAX_TICKS
WAITING :: 0
ASSESSING :: 1
INSIDE :: 2
UP :: 3
IA :: i64(16807)
IM :: i64(2147483647)
IQ :: i64(127773)
IR :: i64(2836)
MASK :: i64(123459876)

Patient :: struct {
	next, previous, time_left, elapsed, hospital_visits: int,
}

Village :: struct {
	label, level, free_personnel: int,
	seed: i64,
	head, tail: [4]int,
}

queue_push :: proc "contextless" (village: ^Village, queue, patient_id: int,
		patients: [^]Patient) {
	patients[patient_id].previous = village.tail[queue]
	patients[patient_id].next = -1
	if village.tail[queue] >= 0 do patients[village.tail[queue]].next = patient_id
	else do village.head[queue] = patient_id
	village.tail[queue] = patient_id
}

queue_remove :: proc "contextless" (village: ^Village, queue, patient_id: int,
		patients: [^]Patient) {
	previous := patients[patient_id].previous
	next := patients[patient_id].next
	if previous >= 0 do patients[previous].next = next
	else do village.head[queue] = next
	if next >= 0 do patients[next].previous = previous
	else do village.tail[queue] = previous
	patients[patient_id].next = -1
	patients[patient_id].previous = -1
}

health_random :: proc "contextless" (village: ^Village) -> f32 {
	state := village.seed ^ MASK
	quotient := state / IQ
	state = IA * (state - quotient * IQ) - IR * quotient
	state = state ^ MASK
	if state < 0 do state += IM
	value := f32((1.0 / f64(IM)) * f64(state))
	village.seed = i64(value * f32(IM))
	return value
}

admit_patient :: proc "contextless" (village: ^Village, patient_id: int, patients: [^]Patient) {
	patients[patient_id].hospital_visits += 1
	if village.free_personnel > 0 {
		village.free_personnel -= 1
		patients[patient_id].time_left = 3
		patients[patient_id].elapsed += 3
		queue_push(village, ASSESSING, patient_id, patients)
	} else {
		queue_push(village, WAITING, patient_id, patients)
	}
}

build_postorder :: proc "contextless" (label, village_count: int,
		order: [^]int, order_length: ^int) {
	for offset := 4; offset >= 1; offset -= 1 {
		child := label * 4 + offset
		if child < village_count do build_postorder(child, village_count, order, order_length)
	}
	order[order_length^] = label
	order_length^ += 1
}

simulate_village :: proc "contextless" (label, village_count: int,
		villages: [^]Village, patients: [^]Patient, patient_count, discharged: ^int) {
	village := &villages[label]
	for offset := 4; offset >= 1; offset -= 1 {
		child_label := label * 4 + offset
		if child_label >= village_count do continue
		child := &villages[child_label]
		patient_id := child.head[UP]
		for patient_id >= 0 {
			next_id := patients[patient_id].next
			queue_remove(child, UP, patient_id, patients)
			admit_patient(village, patient_id, patients)
			patient_id = next_id
		}
	}

	patient_id := village.head[INSIDE]
	for patient_id >= 0 {
		next_id := patients[patient_id].next
		patients[patient_id].time_left -= 1
		if patients[patient_id].time_left == 0 {
			village.free_personnel += 1
			queue_remove(village, INSIDE, patient_id, patients)
			discharged^ += 1
		}
		patient_id = next_id
	}

	patient_id = village.head[ASSESSING]
	for patient_id >= 0 {
		next_id := patients[patient_id].next
		patients[patient_id].time_left -= 1
		if patients[patient_id].time_left == 0 {
			random_value := health_random(village)
			queue_remove(village, ASSESSING, patient_id, patients)
			if f64(random_value) > 0.1 || village.label == 0 {
				patients[patient_id].time_left = 10
				patients[patient_id].elapsed += 10
				queue_push(village, INSIDE, patient_id, patients)
			} else {
				village.free_personnel += 1
				queue_push(village, UP, patient_id, patients)
			}
		}
		patient_id = next_id
	}

	patient_id = village.head[WAITING]
	for patient_id >= 0 {
		next_id := patients[patient_id].next
		if village.free_personnel > 0 {
			village.free_personnel -= 1
			patients[patient_id].time_left = 3
			patients[patient_id].elapsed += 3
			queue_remove(village, WAITING, patient_id, patients)
			queue_push(village, ASSESSING, patient_id, patients)
		} else {
			patients[patient_id].elapsed += 1
		}
		patient_id = next_id
	}

	if f64(health_random(village)) > 0.666 {
		new_patient := patient_count^
		patient_count^ += 1
		patients[new_patient] = Patient{next = -1}
		admit_patient(village, new_patient, patients)
	}
}

@(export)
olden_health :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	level, ticks, seed := input[0], input[1], input[2]
	if level < 1 || level > MAX_LEVEL || ticks < 0 || ticks > MAX_TICKS || seed != 1 do return -1
	village_count, layer_size := 0, 1
	for _ := 0; _ < int(level); _ += 1 { village_count += layer_size; layer_size *= 4 }
	var villages: [MAX_VILLAGES]Village
	for label := 0; label < village_count; label += 1 {
		village := &villages[label]
		village.label = label
		village.level = int(level)
		if label > 0 do village.level = villages[(label-1)/4].level - 1
		village.free_personnel = 1 << u32(village.level-1)
		village.seed = i64(label) * (IQ + seed)
		for queue := 0; queue < 4; queue += 1 { village.head[queue] = -1; village.tail[queue] = -1 }
	}
	var order: [MAX_VILLAGES]int
	order_length := 0
	build_postorder(0, village_count, &order[0], &order_length)
	var patients: [MAX_PATIENTS]Patient
	patient_count, discharged := 0, 0
	for _ := 0; _ < int(ticks); _ += 1 {
		for index := 0; index < order_length; index += 1 {
			simulate_village(order[index], village_count, &villages[0], &patients[0], &patient_count, &discharged)
		}
	}
	return i64(discharged)
}
