package problem205

MAX_TOTAL :: 36
SCALE :: i64(10_000_000)

distribution :: proc(sides, dice: i64, output: ^[37]i64) {
    current: [37]i64 = {}
    next: [37]i64 = {}
    current[0] = 1
    for die := i64(0); die < dice; die += 1 {
        for total := 0; total <= MAX_TOTAL; total += 1 { next[total] = 0 }
        for total := 0; total <= MAX_TOTAL; total += 1 {
            if current[total] == 0 do continue
            for face := i64(1); face <= sides; face += 1 { next[total + int(face)] += current[total] }
        }
        current = next
    }
    output^ = current
}

@(export)
problem205 :: proc "c" (placeholder: i64) -> i64 {
    if placeholder != 0 do return -1
    peter, colin: [37]i64 = {}, {}
    distribution(4, 9, &peter)
    distribution(6, 6, &colin)
    wins, colin_below := i64(0), i64(0)
    for total := 0; total <= MAX_TOTAL; total += 1 {
        if total >= 9 { wins += peter[total] * colin_below }
        colin_below += colin[total]
    }
    games := i64(262144) * 46656
    scaled := wins * SCALE
    rounded := scaled / games
    remainder := scaled % games
    if 2 * remainder > games || (2 * remainder == games && rounded % 2 != 0) { rounded += 1 }
    return rounded
}
