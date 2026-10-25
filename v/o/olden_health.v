module olden_health

const max_level = 4
const max_ticks = 40
const max_villages = 85
const max_patients = max_villages * max_ticks
const waiting = 0
const assessing = 1
const inside = 2
const up = 3
const ia = i64(16807)
const im = i64(2147483647)
const iq = i64(127773)
const ir = i64(2836)
const mask = i64(123459876)

struct HealthPatient {
	mut:
		next int
		previous int
		time_left int
		elapsed int
		hospital_visits int
}

struct HealthVillage {
	mut:
		label int
		level int
		free_personnel int
		seed i64
		head [4]int
		tail [4]int
}

fn queue_push(mut villages []HealthVillage, mut patients []HealthPatient,
		village_id int, queue int, patient_id int) {
	patients[patient_id].previous = villages[village_id].tail[queue]
	patients[patient_id].next = -1
	if villages[village_id].tail[queue] >= 0 {
		patients[villages[village_id].tail[queue]].next = patient_id
	} else {
		villages[village_id].head[queue] = patient_id
	}
	villages[village_id].tail[queue] = patient_id
}

fn queue_remove(mut villages []HealthVillage, mut patients []HealthPatient,
		village_id int, queue int, patient_id int) {
	previous := patients[patient_id].previous
	next := patients[patient_id].next
	if previous >= 0 {
		patients[previous].next = next
	} else {
		villages[village_id].head[queue] = next
	}
	if next >= 0 {
		patients[next].previous = previous
	} else {
		villages[village_id].tail[queue] = previous
	}
	patients[patient_id].next = -1
	patients[patient_id].previous = -1
}

fn health_random(mut villages []HealthVillage, village_id int) f32 {
	mut state := villages[village_id].seed ^ mask
	quotient := state / iq
	state = ia * (state - quotient * iq) - ir * quotient
	state = state ^ mask
	if state < 0 { state += im }
	value := f32((1.0 / f64(im)) * f64(state))
	villages[village_id].seed = i64(value * f32(im))
	return value
}

fn admit_patient(mut villages []HealthVillage, mut patients []HealthPatient,
		village_id int, patient_id int) {
	patients[patient_id].hospital_visits++
	if villages[village_id].free_personnel > 0 {
		villages[village_id].free_personnel--
		patients[patient_id].time_left = 3
		patients[patient_id].elapsed += 3
		queue_push(mut villages, mut patients, village_id, assessing, patient_id)
	} else {
		queue_push(mut villages, mut patients, village_id, waiting, patient_id)
	}
}

fn build_postorder(label int, village_count int, mut order []int, mut order_length int) {
	for offset := 4; offset >= 1; offset-- {
		child := label * 4 + offset
		if child < village_count {
			build_postorder(child, village_count, mut order, mut order_length)
		}
	}
	order[order_length] = label
	order_length++
}

fn simulate_village(label int, village_count int, mut villages []HealthVillage,
		mut patients []HealthPatient, mut patient_count int, mut discharged i64) {
	for offset := 4; offset >= 1; offset-- {
		child_label := label * 4 + offset
		if child_label >= village_count { continue }
		mut patient_id := villages[child_label].head[up]
		for patient_id >= 0 {
			next_id := patients[patient_id].next
			queue_remove(mut villages, mut patients, child_label, up, patient_id)
			admit_patient(mut villages, mut patients, label, patient_id)
			patient_id = next_id
		}
	}

	mut patient_id := villages[label].head[inside]
	for patient_id >= 0 {
		next_id := patients[patient_id].next
		patients[patient_id].time_left--
		if patients[patient_id].time_left == 0 {
			villages[label].free_personnel++
			queue_remove(mut villages, mut patients, label, inside, patient_id)
			discharged++
		}
		patient_id = next_id
	}

	patient_id = villages[label].head[assessing]
	for patient_id >= 0 {
		next_id := patients[patient_id].next
		patients[patient_id].time_left--
		if patients[patient_id].time_left == 0 {
			random_value := health_random(mut villages, label)
			queue_remove(mut villages, mut patients, label, assessing, patient_id)
			if f64(random_value) > 0.1 || villages[label].label == 0 {
				patients[patient_id].time_left = 10
				patients[patient_id].elapsed += 10
				queue_push(mut villages, mut patients, label, inside, patient_id)
			} else {
				villages[label].free_personnel++
				queue_push(mut villages, mut patients, label, up, patient_id)
			}
		}
		patient_id = next_id
	}

	patient_id = villages[label].head[waiting]
	for patient_id >= 0 {
		next_id := patients[patient_id].next
		if villages[label].free_personnel > 0 {
			villages[label].free_personnel--
			patients[patient_id].time_left = 3
			patients[patient_id].elapsed += 3
			queue_remove(mut villages, mut patients, label, waiting, patient_id)
			queue_push(mut villages, mut patients, label, assessing, patient_id)
		} else {
			patients[patient_id].elapsed++
		}
		patient_id = next_id
	}

	if f64(health_random(mut villages, label)) > 0.666 {
		new_patient := patient_count
		patient_count++
		patients[new_patient] = HealthPatient{next: -1}
		admit_patient(mut villages, mut patients, label, new_patient)
	}
}

@[export: 'olden_health']
pub fn olden_health(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 3 { return -1 }
		level := input[0]
		ticks := input[1]
		seed := input[2]
		if level < 1 || level > max_level || ticks < 0 || ticks > max_ticks || seed != 1 { return -1 }
		mut village_count := 0
		mut layer_size := 1
		for _ in 0 .. int(level) { village_count += layer_size; layer_size *= 4 }
		mut villages := []HealthVillage{len: max_villages}
		for label in 0 .. village_count {
			villages[label].label = label
			villages[label].level = if label == 0 { int(level) } else { villages[(label - 1) / 4].level - 1 }
			villages[label].free_personnel = 1 << (villages[label].level - 1)
			villages[label].seed = i64(label) * (iq + seed)
			for queue in 0 .. 4 { villages[label].head[queue] = -1; villages[label].tail[queue] = -1 }
		}
		mut order := []int{len: max_villages}
		mut order_length := 0
		build_postorder(0, village_count, mut order, mut order_length)
		mut patients := []HealthPatient{len: max_patients}
		mut patient_count := 0
		mut discharged := i64(0)
		for _ in 0 .. int(ticks) {
			for index in 0 .. order_length {
				simulate_village(order[index], village_count, mut villages, mut patients, mut patient_count, mut discharged)
			}
		}
		return discharged
	}
}
