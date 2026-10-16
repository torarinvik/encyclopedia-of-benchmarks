module depreciation;

const usz MAX_YEARS = 16;
const long MAX_VALUE_MICRO = 1000000000000;
const long MAX_RATE_PPM = 1000000;
const long MAX_UNITS = 1000000000;
extern fn double fabs(double value);
extern fn double fmin(double left, double right);
extern fn double fmax(double left, double right);

fn void write_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long depreciation(long* values, usz length, char* output, usz output_capacity)
        @export("depreciation") {
    if (values == null || length < 4 || length > MAX_YEARS + 4) return -1;
    long method = values[0];
    usz years = 0;
    long purchase_scaled = 0, residual_scaled = 0;
    double rate = 0.0;
    if (method == 0 || method == 3 || method == 4) {
        if (length != 4 || values[1] < 1 || values[1] > (long)MAX_YEARS) return -1;
        years = (usz)values[1]; purchase_scaled = values[2]; residual_scaled = values[3];
    } else if (method == 1) {
        if (length != 5 || values[1] < 1 || values[1] > (long)MAX_YEARS ||
            values[4] < 1 || values[4] > MAX_RATE_PPM) return -1;
        years = (usz)values[1]; purchase_scaled = values[2]; residual_scaled = values[3];
        rate = (double)values[4] / 1000000.0;
    } else if (method == 2) {
        if (length < 5) return -1;
        years = length - 4;
        if (years > MAX_YEARS || values[3] < 1 || values[3] > MAX_UNITS) return -1;
        purchase_scaled = values[1]; residual_scaled = values[2];
        double unit_sum = 0.0;
        for (usz i = 0; i < years; i++) {
            if (values[4 + i] < -MAX_UNITS || values[4 + i] > MAX_UNITS) return -1;
            unit_sum += (double)values[4 + i];
        }
        if (fabs(unit_sum - (double)values[3]) > 1.0e-6 * (double)values[3]) return -1;
    } else return -1;

    if (purchase_scaled < 0 || purchase_scaled > MAX_VALUE_MICRO ||
        residual_scaled < -MAX_VALUE_MICRO || residual_scaled > purchase_scaled) return -1;
    double purchase = (double)purchase_scaled / 1000000.0;
    double residual = (double)residual_scaled / 1000000.0;
    double depreciable_cost = purchase - residual;
    double[MAX_YEARS] schedule = zeroed;

    if (method == 0) {
        double annual = depreciable_cost / (double)years;
        double accumulated = 0.0;
        for (usz period = 0; period < years; period++) {
            if (period == years - 1) schedule[period] = depreciable_cost - accumulated;
            else { accumulated += annual; schedule[period] = annual; }
        }
    } else if (method == 1) {
        double book_value = purchase;
        for (usz period = 0; period < years; period++) {
            if (period == years - 1) schedule[period] = book_value - residual;
            else {
                double expense = fmin(book_value * rate, book_value - residual);
                schedule[period] = expense; book_value -= expense;
            }
        }
    } else if (method == 2) {
        double per_unit = depreciable_cost / (double)values[3];
        double accumulated = 0.0;
        for (usz period = 0; period < years; period++) {
            if (period == years - 1) schedule[period] = depreciable_cost - accumulated;
            else {
                double expense = (double)values[4 + period] * per_unit;
                accumulated += expense; schedule[period] = expense;
            }
        }
    } else if (method == 3) {
        double syd = (double)years * ((double)years + 1.0) / 2.0;
        double accumulated = 0.0;
        for (usz period = 1; period <= years; period++) {
            if (period == years) schedule[period - 1] = depreciable_cost - accumulated;
            else {
                double expense = ((double)(years - period + 1) / syd) * depreciable_cost;
                accumulated += expense; schedule[period - 1] = expense;
            }
        }
    } else {
        double ddb_rate = 2.0 / (double)years;
        double book_value = purchase, accumulated = 0.0;
        for (usz period = 1; period <= years; period++) {
            double remaining = (double)(years - period + 1);
            double ddb = fmax(book_value * ddb_rate, 0.0);
            double straight_line = fmax((book_value - residual) / remaining, 0.0);
            double expense = fmin(fmax(ddb, straight_line), book_value - residual);
            if (period == years) schedule[period - 1] = depreciable_cost - accumulated;
            else { accumulated += expense; schedule[period - 1] = expense; book_value -= expense; }
        }
    }

    usz output_bytes = years * 8;
    if (output == null || output_bytes > output_capacity) return -2;
    for (usz i = 0; i < years; i++) write_f64_le(output, i * 8, schedule[i]);
    return (long)output_bytes;
}
