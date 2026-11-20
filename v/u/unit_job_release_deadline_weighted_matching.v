module unit_job_release_deadline_weighted_matching

struct Schedule {
    starts [32]int
    ends [32]int
mut:
    slots [32]int
    seen [32]bool
}

fn (mut s Schedule) assign(job int) bool {
    for slot in s.starts[job] .. s.ends[job]+1 {
        if s.seen[slot] { continue }
        s.seen[slot] = true
        old := s.slots[slot]
        if old < 0 || s.assign(old) {
            s.slots[slot] = job
            return true
        }
    }
    return false
}

@[export: 'unit_job_release_deadline_weighted_matching']
pub fn unit_job_release_deadline_weighted_matching(input &i64, length usize) i64 {
    if input == nil || length < 1 || length > 98 { return -1 }
    unsafe {
        if input[0] < 0 || input[0] > 32 { return -1 }
        n := int(input[0])
        if length != usize(1+3*n) { return -1 }
        mut starts := [32]int{}
        mut ends := [32]int{}
        mut slots := [32]int{}
        mut weights := [32]i64{}
        mut order := [32]int{}
        for i in 0 .. 32 { slots[i] = -1 }
        for i in 0 .. n {
            r, d, w := input[1+3*i], input[2+3*i], input[3+3*i]
            if r < 0 || d < r || d >= 32 || w < 0 || w > 1000000 { return -1 }
            starts[i], ends[i], weights[i] = int(r), int(d), w
            mut j := i
            for j > 0 && weights[order[j-1]] < w { order[j] = order[j-1]; j-- }
            order[j] = i
        }
        mut schedule := Schedule{starts: starts, ends: ends, slots: slots}
        mut total := i64(0)
        for i in 0 .. n {
            schedule.seen = [32]bool{}
            job := order[i]
            if schedule.assign(job) { total += weights[job] }
        }
        return total
    }
}
