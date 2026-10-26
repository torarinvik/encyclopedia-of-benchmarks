const MAX_R: usize = 8;
const MAX_H: usize = 8;
const MAX_INPUT: usize = 154;
const MAX_OUTPUT: usize = 64;

unsafe fn put64(output: *mut u8, position: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(position + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn hospitals_residents_rgs(input: *const i64,
    length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT { return -1; }
    let r64 = *input;
    let h64 = *input.add(1);
    if r64 < 1 || r64 > MAX_R as i64 || h64 < 1 || h64 > MAX_H as i64 { return -1; }
    let r = r64 as usize;
    let h = h64 as usize;
    if length != 2 + 2*h + r + 2*r*h { return -1; }
    let cap_offset = 2;
    let rlen_offset = cap_offset + h;
    let rpref_offset = rlen_offset + r;
    let hlen_offset = rpref_offset + r*h;
    let hpref_offset = hlen_offset + h;
    let mut capacities = [0i64; MAX_H];
    let mut resident_length = [0i64; MAX_R];
    let mut resident_pref = [-1i64; MAX_R * MAX_H];
    let mut hospital_length = [0i64; MAX_H];
    let mut hospital_rank = [-1i64; MAX_H * MAX_R];
    let mut assignment = [-1i64; MAX_R];
    let mut next_choice = [0usize; MAX_R];
    let mut occupancy = [0usize; MAX_H];
    for hospital in 0..h {
        capacities[hospital] = *input.add(cap_offset + hospital);
        hospital_length[hospital] = *input.add(hlen_offset + hospital);
        if capacities[hospital] < 1 || capacities[hospital] > r64 ||
            hospital_length[hospital] < 0 || hospital_length[hospital] > r64 { return -1; }
    }
    for resident in 0..r {
        resident_length[resident] = *input.add(rlen_offset + resident);
        if resident_length[resident] < 0 || resident_length[resident] > h64 { return -1; }
        let mut seen = [false; MAX_H];
        for slot in 0..h {
            let value = *input.add(rpref_offset + resident*h + slot);
            if slot < resident_length[resident] as usize {
                if value < 0 || value >= h64 || seen[value as usize] { return -1; }
                seen[value as usize] = true;
                resident_pref[resident*MAX_H + slot] = value;
            } else if value != -1 { return -1; }
        }
    }
    for hospital in 0..h {
        let mut seen = [false; MAX_R];
        for slot in 0..r {
            let value = *input.add(hpref_offset + hospital*r + slot);
            if slot < hospital_length[hospital] as usize {
                if value < 0 || value >= r64 || seen[value as usize] { return -1; }
                seen[value as usize] = true;
                hospital_rank[hospital*MAX_R + value as usize] = slot as i64;
            } else if value != -1 { return -1; }
        }
    }
    for resident in 0..r {
        for hospital in 0..h {
            let mut accepted = false;
            for slot in 0..resident_length[resident] as usize {
                if resident_pref[resident*MAX_H + slot] == hospital as i64 { accepted = true; }
            }
            if accepted != (hospital_rank[hospital*MAX_R + resident] >= 0) { return -1; }
        }
    }
    let output_bytes = 8*r;
    if output.is_null() || capacity < output_bytes { return -2; }

    loop {
        let mut proposer = r;
        for resident in 0..r {
            if assignment[resident] == -1 && next_choice[resident] < resident_length[resident] as usize {
                proposer = resident;
                break;
            }
        }
        if proposer == r { break; }
        let hospital = resident_pref[proposer*MAX_H + next_choice[proposer]] as usize;
        next_choice[proposer] += 1;
        if occupancy[hospital] < capacities[hospital] as usize {
            assignment[proposer] = hospital as i64;
            occupancy[hospital] += 1;
        } else {
            let mut worst = r;
            for resident in 0..r {
                if assignment[resident] == hospital as i64 &&
                    (worst == r || hospital_rank[hospital*MAX_R + resident] > hospital_rank[hospital*MAX_R + worst]) {
                    worst = resident;
                }
            }
            if worst == r { return -1; }
            if hospital_rank[hospital*MAX_R + proposer] < hospital_rank[hospital*MAX_R + worst] {
                assignment[worst] = -1;
                assignment[proposer] = hospital as i64;
            }
        }
    }
    let mut staged = [0u8; MAX_OUTPUT];
    for resident in 0..r { put64(staged.as_mut_ptr(), 8*resident, assignment[resident]); }
    for byte in 0..output_bytes { *output.add(byte) = staged[byte]; }
    output_bytes as i64
}
