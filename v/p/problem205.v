module problem205

const max_total = 36
const scale = i64(10000000)

fn distribution(sides int, dice int) []i64 {
	mut current := []i64{len: 37, init: 0}
	current[0] = 1
	for _ in 0 .. dice {
		mut next := []i64{len: 37, init: 0}
		for total in 0 .. max_total + 1 {
			if current[total] == 0 { continue }
			for face in 1 .. sides + 1 { next[total + face] += current[total] }
		}
		current = next
	}
	return current
}

@[export: 'problem205']
pub fn problem205(placeholder i64) i64 {
	if placeholder != 0 { return -1 }
	peter := distribution(4, 9)
	colin := distribution(6, 6)
	mut wins := i64(0)
	mut colin_below := i64(0)
	for total in 0 .. max_total + 1 {
		if total >= 9 { wins += peter[total] * colin_below }
		colin_below += colin[total]
	}
	games := i64(262144) * 46656
	scaled := wins * scale
	mut rounded := scaled / games
	remainder := scaled % games
	if 2 * remainder > games || (2 * remainder == games && rounded % 2 != 0) { rounded++ }
	return rounded
}
