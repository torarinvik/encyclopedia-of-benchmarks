module find_the_town_judge;

const MAX_PEOPLE = 1000;
const MAX_TRUST_ROWS = 10000;
const MAX_INPUT_LENGTH = 20002;

fn long find_the_town_judge(long* values, usz length) @export("find_the_town_judge") {
    if (length < 2 || length > MAX_INPUT_LENGTH || values == null) return -2;
    long people = values[0];
    long trust_count = values[1];
    if (people < 1 || people > MAX_PEOPLE || trust_count < 0 || trust_count > MAX_TRUST_ROWS)
        return -2;
    usz edge_count = (usz)trust_count;
    if (length != 2 + 2 * edge_count) return -2;

    long[MAX_PEOPLE + 1] incoming;
    long[MAX_PEOPLE + 1] outgoing;
    for (usz person = 0; person <= MAX_PEOPLE; person++) {
        incoming[person] = 0;
        outgoing[person] = 0;
    }
    for (usz edge = 0; edge < edge_count; edge++) {
        long from = values[2 + 2 * edge];
        long to = values[3 + 2 * edge];
        if (from < 1 || from > people || to < 1 || to > people || from == to) return -2;
        outgoing[(usz)from]++;
        incoming[(usz)to]++;
    }

    long judge = -1;
    for (long person = 1; person <= people; person++) {
        if (incoming[(usz)person] == people - 1 && outgoing[(usz)person] == 0) {
            if (judge != -1) return -1;
            judge = person;
        }
    }
    return judge;
}
