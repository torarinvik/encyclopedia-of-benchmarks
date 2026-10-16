module problem191;

fn long problem191(long days) @export("problem191") {
    if (days < 0 || days > 65) return -1;
    long[396] ways = {0};
    for (int absent = 0; absent <= 1; absent++)
        for (int late = 0; late <= 2; late++) ways[absent * 3 + late] = 1;
    for (long remaining = 1; remaining <= days; remaining++) {
        for (int absent = 0; absent <= 1; absent++) {
            for (int late = 0; late <= 2; late++) {
                long previous = (remaining - 1) * 6;
                long late_state = late < 2 ? ways[previous + absent * 3 + late + 1] : 0;
                long absent_state = absent == 0 ? ways[previous + 3] : 0;
                long on_time_state = ways[previous + absent * 3];
                ways[remaining * 6 + absent * 3 + late] = late_state + absent_state + on_time_state;
            }
        }
    }
    return ways[days * 6];
}
