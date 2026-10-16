const DEAL_COUNT: usize = 1000;
const VALUES_PER_DEAL: usize = 10;

fn rankHand(cards: [5]i64) [6]i64 {
    var ranks: [5]i64 = undefined;
    var suits: [5]i64 = undefined;
    var counts = [_]i64{0} ** 15;
    for (0..5) |i| {
        ranks[i] = @divTrunc(cards[i], 4) + 2;
        suits[i] = @rem(cards[i], 4);
        counts[@intCast(ranks[i])] += 1;
    }
    for (1..5) |i| {
        const value = ranks[i];
        var j = i;
        while (j > 0 and ranks[j - 1] < value) {
            ranks[j] = ranks[j - 1];
            j -= 1;
        }
        ranks[j] = value;
    }
    var score = [_]i64{0} ** 6;
    var flush = true;
    for (1..5) |i| if (suits[i] != suits[0]) { flush = false; };
    var distinct = true;
    for (2..15) |rank| if (counts[rank] > 1) { distinct = false; };
    var straight_high: i64 = 0;
    if (distinct and ranks[0] - ranks[4] == 4) {
        straight_high = ranks[0];
    } else if (distinct and ranks[0] == 14 and ranks[1] == 5 and ranks[2] == 4 and ranks[3] == 3 and ranks[4] == 2) {
        straight_high = 5;
    }
    var four: i64 = 0;
    var three: i64 = 0;
    var pair_high: i64 = 0;
    var pair_low: i64 = 0;
    var singles = [_]i64{0} ** 5;
    var single_count: usize = 0;
    var rank: i64 = 14;
    while (rank >= 2) : (rank -= 1) {
        const count = counts[@intCast(rank)];
        if (count == 4) {
            four = rank;
        } else if (count == 3) {
            three = rank;
        } else if (count == 2) {
            if (pair_high == 0) { pair_high = rank; } else { pair_low = rank; }
        } else if (count == 1) {
            singles[single_count] = rank;
            single_count += 1;
        }
    }
    if (flush and straight_high != 0) {
        score[0] = if (straight_high == 14) 9 else 8;
        score[1] = straight_high;
    } else if (four != 0) {
        score[0] = 7; score[1] = four; score[2] = singles[0];
    } else if (three != 0 and pair_high != 0) {
        score[0] = 6; score[1] = three; score[2] = pair_high;
    } else if (flush) {
        score[0] = 5;
        for (0..5) |i| score[i + 1] = ranks[i];
    } else if (straight_high != 0) {
        score[0] = 4; score[1] = straight_high;
    } else if (three != 0) {
        score[0] = 3; score[1] = three; score[2] = singles[0]; score[3] = singles[1];
    } else if (pair_low != 0) {
        score[0] = 2; score[1] = pair_high; score[2] = pair_low; score[3] = singles[0];
    } else if (pair_high != 0) {
        score[0] = 1; score[1] = pair_high; score[2] = singles[0]; score[3] = singles[1]; score[4] = singles[2];
    } else {
        score[0] = 0;
        for (0..5) |i| score[i + 1] = ranks[i];
    }
    return score;
}

pub export fn problem54(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != DEAL_COUNT * VALUES_PER_DEAL) return -1;
    var wins: i64 = 0;
    for (0..DEAL_COUNT) |deal| {
        const offset = deal * VALUES_PER_DEAL;
        for (0..VALUES_PER_DEAL) |i| {
            const card = input[offset + i];
            if (card < 0 or card >= 52) return -1;
            for (0..i) |previous| if (input[offset + previous] == card) return -1;
        }
        var first_cards: [5]i64 = undefined;
        var second_cards: [5]i64 = undefined;
        for (0..5) |i| {
            first_cards[i] = input[offset + i];
            second_cards[i] = input[offset + 5 + i];
        }
        const first = rankHand(first_cards);
        const second = rankHand(second_cards);
        for (0..6) |i| {
            if (first[i] > second[i]) { wins += 1; break; }
            if (first[i] < second[i]) break;
        }
    }
    return wins;
}
