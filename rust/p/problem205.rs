/// Return the Peter-over-Colin win probability in units of 1e-7.
const MAX_TOTAL: usize = 36;
const SCALE: i64 = 10_000_000;

fn distribution(sides: usize, dice: usize) -> [i64; 37] {
    let mut current = [0i64; 37];
    current[0] = 1;
    for _ in 0..dice {
        let mut next = [0i64; 37];
        for total in 0..=MAX_TOTAL {
            if current[total] != 0 {
                for face in 1..=sides { next[total + face] += current[total]; }
            }
        }
        current = next;
    }
    current
}

#[no_mangle]
pub extern "C" fn problem205(placeholder: i64) -> i64 {
    if placeholder != 0 { return -1; }
    let peter = distribution(4, 9);
    let colin = distribution(6, 6);
    let mut wins = 0i64;
    let mut colin_below = 0i64;
    for total in 0..=MAX_TOTAL {
        if total >= 9 { wins += peter[total] * colin_below; }
        colin_below += colin[total];
    }
    let games = 262_144i64 * 46_656;
    let scaled = wins * SCALE;
    let mut rounded = scaled / games;
    let remainder = scaled % games;
    if 2 * remainder > games || (2 * remainder == games && rounded % 2 != 0) { rounded += 1; }
    rounded
}
