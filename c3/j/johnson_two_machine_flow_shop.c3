module johnson_two_machine_flow_shop;

const int MAX_JOBS = 8;
const int MAX_TIME = 1000;

fn long johnson_two_machine_flow_shop(long* input, usz length) @export("johnson_two_machine_flow_shop") {
    if (input == null || length < 1 || input[0] < 1 || input[0] > MAX_JOBS) return -1;
    int count = (int)input[0];
    if (length != (usz)(1 + 2 * count)) return -1;
    long[MAX_JOBS] first = {}, second = {};
    int[MAX_JOBS] early = {}, late = {};
    int early_count = 0, late_count = 0;
    for (int job = 0; job < count; job++) {
        first[job] = input[1 + 2 * job];
        second[job] = input[2 + 2 * job];
        if (first[job] < 0 || first[job] > MAX_TIME || second[job] < 0 || second[job] > MAX_TIME) return -1;
        bool is_early = first[job] < second[job];
        int position = is_early ? early_count : late_count;
        while (position > 0) {
            int previous = is_early ? early[position - 1] : late[position - 1];
            bool comes_before = is_early
                ? (first[job] < first[previous] || (first[job] == first[previous] && job < previous))
                : (second[job] > second[previous] || (second[job] == second[previous] && job < previous));
            if (!comes_before) break;
            if (is_early) early[position] = previous; else late[position] = previous;
            position--;
        }
        if (is_early) { early[position] = job; early_count++; }
        else { late[position] = job; late_count++; }
    }
    long first_finish = 0, second_finish = 0;
    for (int index = 0; index < count; index++) {
        int job = index < early_count ? early[index] : late[index - early_count];
        first_finish += first[job];
        if (second_finish < first_finish) second_finish = first_finish;
        second_finish += second[job];
    }
    return second_finish;
}
