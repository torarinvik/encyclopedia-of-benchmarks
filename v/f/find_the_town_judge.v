module find_the_town_judge

const max_people = 1000
const max_trust_rows = 10000

@[export: 'find_the_town_judge']
pub fn find_the_town_judge(values &i64, length usize) i64 {
	if length < 2 || length > 20002 { return -2 }
	unsafe {
		people := values[0]
		trust_count := values[1]
		if people < 1 || people > max_people || trust_count < 0 || trust_count > max_trust_rows { return -2 }
		edge_count := usize(trust_count)
		if length != 2 + 2 * edge_count { return -2 }
		mut incoming := [1001]i64{init: 0}
		mut outgoing := [1001]i64{init: 0}
		for edge in 0 .. edge_count {
			from := values[2 + 2 * edge]
			to := values[3 + 2 * edge]
			if from < 1 || from > people || to < 1 || to > people || from == to { return -2 }
			outgoing[usize(from)]++
			incoming[usize(to)]++
		}
		mut judge := i64(-1)
		for person in i64(1) .. people + 1 {
			if incoming[usize(person)] == people - 1 && outgoing[usize(person)] == 0 {
				if judge != -1 { return -1 }
				judge = person
			}
		}
		return judge
	}
}
