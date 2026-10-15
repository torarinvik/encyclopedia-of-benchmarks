/// Find the unique person trusted by everyone else and who trusts nobody.
const MAX_PEOPLE: i64 = 1000;
const MAX_TRUST_ROWS: i64 = 10000;

#[no_mangle]
pub unsafe extern "C" fn find_the_town_judge(values: *const i64, length: usize) -> i64 {
    if length < 2 || length > 20002 || values.is_null() { return -2; }
    let people = *values;
    let trust_count = *values.add(1);
    if people < 1 || people > MAX_PEOPLE || trust_count < 0 || trust_count > MAX_TRUST_ROWS {
        return -2;
    }
    let edge_count = trust_count as usize;
    if length != 2 + 2 * edge_count { return -2; }

    let mut incoming = [0i64; 1001];
    let mut outgoing = [0i64; 1001];
    for edge in 0..edge_count {
        let from = *values.add(2 + 2 * edge);
        let to = *values.add(3 + 2 * edge);
        if from < 1 || from > people || to < 1 || to > people || from == to { return -2; }
        outgoing[from as usize] += 1;
        incoming[to as usize] += 1;
    }
    let mut judge = -1;
    for person in 1..=people as usize {
        if incoming[person] == people - 1 && outgoing[person] == 0 {
            if judge != -1 { return -1; }
            judge = person as i64;
        }
    }
    judge
}
