module similarity_search;
extern fn double sqrt(double value);
fn void put_u64(ulong bits, char* output, usz offset) { for (usz b = 0; b < 8; b++) { output[offset+b] = (char)(bits & 255); bits >>= 8; } }
fn void put_i64(long value, char* output, usz offset) { put_u64(@bitcast(ulong, value), output, offset); }
fn void put_f64(double value, char* output, usz offset) { put_u64(@bitcast(ulong, value), output, offset); }

fn long similarity_search(long* input, usz length, char* output, usz output_capacity) @export("similarity_search") {
    if (input == null || length < 3 || length > 643) return -1;
    long rv = input[0], qv = input[1], fv = input[2];
    if (rv < 1 || rv > 32 || qv < 1 || qv > 8 || fv < 1 || fv > 16) return -1;
    usz rows = (usz)rv, queries = (usz)qv, features = (usz)fv;
    if (length != 3 + (rows + queries) * features) return -1;
    for (usz i = 0; i < (rows + queries) * features; i++) if (input[3+i] < -1000000 || input[3+i] > 1000000) return -1;
    usz record = 16 + 8 * features, needed = queries * record;
    if (output == null || output_capacity < needed) return -2;
    for (usz query = 0; query < queries; query++) {
        usz best = 0;
        double sum = 0.0;
        for (usz f = 0; f < features; f++) {
            double delta = (double)input[3+f] / 1000000.0 - (double)input[3+rows*features+query*features+f] / 1000000.0;
            sum += delta * delta;
        }
        double best_distance = sqrt(sum);
        for (usz row = 1; row < rows; row++) {
            sum = 0.0;
            for (usz f = 0; f < features; f++) {
                double delta = (double)input[3+row*features+f] / 1000000.0 - (double)input[3+rows*features+query*features+f] / 1000000.0;
                sum += delta * delta;
            }
            double distance = sqrt(sum);
            if (distance < best_distance) { best = row; best_distance = distance; }
        }
        usz base = query * record;
        put_i64((long)best, output, base);
        put_f64(best_distance, output, base + 8);
        for (usz f = 0; f < features; f++) put_i64(input[3+best*features+f], output, base + 16 + 8*f);
    }
    return (long)needed;
}
