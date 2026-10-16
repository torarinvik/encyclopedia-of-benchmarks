module problem101;

fn long question_function(long n) {
    long term = 1;
    long total = 0;
    for (int exponent = 0; exponent <= 10; exponent++) {
        total += exponent % 2 == 0 ? term : -term;
        term *= n;
    }
    return total;
}

fn long problem101(long order) @export("problem101") {
    if (order > 10) return -1;
    if (order <= 0) return 0;
    long[10] data;
    for (int i = 0; i < (int)order; i++) data[i] = question_function(i + 1);
    long total_fit = 0;
    for (int k = 1; k <= (int)order; k++) {
        long[10] row = {0}, differences = {0};
        for (int i = 0; i < k; i++) row[i] = data[i];
        differences[0] = row[0];
        for (int level = 1; level < k; level++) {
            for (int i = 0; i < k - level; i++) row[i] = row[i + 1] - row[i];
            differences[level] = row[0];
        }
        long x = 1;
        long prediction;
        while (true) {
            prediction = 0;
            long choose = 1;
            for (int j = 0; j < k; j++) {
                prediction += differences[j] * choose;
                if (j + 1 < k) choose = choose * (x - 1 - j) / (j + 1);
            }
            if (prediction != question_function(x)) break;
            x++;
        }
        total_fit += prediction;
    }
    return total_fit;
}
