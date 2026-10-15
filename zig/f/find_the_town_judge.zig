const MAX_PEOPLE: i64 = 1000;
const MAX_TRUST_ROWS: i64 = 10000;

export fn find_the_town_judge(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 20002) return -2;
    const people = values[0];
    const trust_count = values[1];
    if (people < 1 or people > MAX_PEOPLE or trust_count < 0 or trust_count > MAX_TRUST_ROWS)
        return -2;
    const edge_count: usize = @intCast(trust_count);
    if (length != 2 + 2 * edge_count) return -2;

    var incoming: [1001]i64 = [_]i64{0} ** 1001;
    var outgoing: [1001]i64 = [_]i64{0} ** 1001;
    for (0..edge_count) |edge| {
        const from = values[2 + 2 * edge];
        const to = values[3 + 2 * edge];
        if (from < 1 or from > people or to < 1 or to > people or from == to) return -2;
        outgoing[@intCast(from)] += 1;
        incoming[@intCast(to)] += 1;
    }
    var judge: i64 = -1;
    var person: i64 = 1;
    while (person <= people) : (person += 1) {
        if (incoming[@intCast(person)] == people - 1 and outgoing[@intCast(person)] == 0) {
            if (judge != -1) return -1;
            judge = person;
        }
    }
    return judge;
}
