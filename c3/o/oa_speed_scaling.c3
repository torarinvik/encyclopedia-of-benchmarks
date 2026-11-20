module oa_speed_scaling;

const usz MAX_JOBS = 2;
const usz MAX_TIME = 4;
const usz MAX_INPUT = 8;
const usz MAX_SEGMENTS = 3;
const usz MAX_OUTPUT = 152;
struct Rat { long n; long d; }
struct Segment { long start; long end; long speed_n; long speed_d; }

fn long oa_gcd(long a, long b) {
    while (b != 0) { long r = a % b; a = b; b = r; }
    return a < 0 ? -a : a;
}
fn Rat oa_make(long n, long d) {
    if (d < 0) { n = -n; d = -d; }
    long g = oa_gcd(n,d);
    return Rat{n/g,d/g};
}
fn Rat oa_add(Rat a, Rat b) { return oa_make(a.n*b.d+b.n*a.d,a.d*b.d); }
fn Rat oa_sub(Rat a, Rat b) { return oa_make(a.n*b.d-b.n*a.d,a.d*b.d); }
fn Rat oa_mul(Rat a, Rat b) { return oa_make(a.n*b.n,a.d*b.d); }
fn Rat oa_div(Rat a, Rat b) { return oa_make(a.n*b.d,a.d*b.n); }
fn Rat oa_int(long value) { return Rat{value,1}; }
fn int oa_cmp(Rat a, Rat b) {
    long left = a.n*b.d, right = b.n*a.d;
    return left > right ? 1 : (left < right ? -1 : 0);
}
fn void oa_put(char* output, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b += 1) { output[at+b] = (char)(bits & 255); bits >>= 8; }
}
fn void oa_segment(Segment* segments, usz* count, long start, long end, Rat speed) {
    if (end <= start || speed.n <= 0) return;
    if (*count > 0 && segments[*count-1].end == start &&
        oa_cmp(speed,oa_make(segments[*count-1].speed_n,segments[*count-1].speed_d)) == 0) {
        segments[*count-1].end = end;
        return;
    }
    segments[*count] = Segment{start,end,speed.n,speed.d};
    *count += 1;
}

fn long oa_speed_scaling(long* input, usz length, char* output, usz capacity)
        @export("oa_speed_scaling") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0];
    if (n64 < 1 || n64 > (long)MAX_JOBS || length != 1+3*(usz)n64) return -1;
    usz n = (usz)n64;
    long[MAX_JOBS] release = zeroed, deadline = zeroed, work = zeroed;
    Rat[MAX_JOBS] remaining = zeroed, completion = zeroed;
    bool[MAX_JOBS] completed = zeroed;
    for (usz j = 0; j < n; j += 1) {
        long r = input[1+3*j], d = input[2+3*j], w = input[3+3*j];
        if (r < 0 || r >= d || d > (long)MAX_TIME || w < 1 || w > 4) return -1;
        release[j] = r; deadline[j] = d; work[j] = w;
        remaining[j] = oa_int(0); completion[j] = oa_int(0);
    }
    Segment[MAX_SEGMENTS] segments = zeroed;
    usz segment_count = 0;
    Rat energy = oa_int(0);
    for (long now = 0; now <= (long)MAX_TIME; now += 1) {
        bool has_arrival = false;
        for (usz j = 0; j < n; j += 1) if (release[j] == now) {
            remaining[j] = oa_int(work[j]); has_arrival = true;
        }
        if (!has_arrival) continue;
        long next_release = (long)MAX_TIME+1;
        for (usz j = 0; j < n; j += 1)
            if (release[j] > now && release[j] < next_release) next_release = release[j];
        int[MAX_JOBS] order = zeroed;
        int count = 0;
        for (usz j = 0; j < n; j += 1)
            if (remaining[j].n > 0 && deadline[j] > now) { order[count] = (int)j; count += 1; }
        for (int i = 1; i < count; i += 1) {
            int value = order[i], k = i;
            while (k > 0 && (deadline[(usz)order[k-1]] > deadline[(usz)value] ||
                  (deadline[(usz)order[k-1]] == deadline[(usz)value] && order[k-1] > value))) {
                order[k] = order[k-1]; k -= 1;
            }
            order[k] = value;
        }
        long left = now;
        while (count > 0) {
            Rat prefix = oa_int(0), best = oa_int(0);
            int best_count = 0;
            for (int k = 1; k <= count; k += 1) {
                prefix = oa_add(prefix,remaining[(usz)order[k-1]]);
                Rat density = oa_div(prefix,oa_int(deadline[(usz)order[k-1]]-left));
                if (best_count == 0 || oa_cmp(density,best) > 0) { best = density; best_count = k; }
            }
            long right = deadline[(usz)order[best_count-1]];
            long stop = right < next_release ? right : next_release;
            oa_segment(&segments[0],&segment_count,left,stop,best);
            energy = oa_add(energy,oa_mul(oa_mul(oa_mul(best,best),best),oa_int(stop-left)));
            Rat cursor = oa_int(left), stop_rat = oa_int(stop);
            for (int k = 0; k < best_count; k += 1) {
                usz j = (usz)order[k];
                Rat finish = oa_add(cursor,oa_div(remaining[j],best));
                if (oa_cmp(finish,stop_rat) <= 0) {
                    completion[j] = finish; completed[j] = true;
                    remaining[j] = oa_int(0); cursor = finish;
                } else {
                    remaining[j] = oa_sub(remaining[j],oa_mul(best,oa_sub(stop_rat,cursor)));
                    cursor = stop_rat;
                    break;
                }
            }
            if (stop < right) break;
            for (int k = best_count; k < count; k += 1) order[k-best_count] = order[k];
            count -= best_count; left = right;
        }
    }
    for (usz j = 0; j < n; j += 1) if (!completed[j]) return -1;
    long[MAX_OUTPUT/8] values = zeroed;
    usz fields = 0;
    values[fields] = (long)segment_count; fields += 1;
    values[fields] = energy.n; fields += 1; values[fields] = energy.d; fields += 1;
    for (usz s = 0; s < segment_count; s += 1) {
        values[fields] = segments[s].start; fields += 1;
        values[fields] = segments[s].end; fields += 1;
        values[fields] = segments[s].speed_n; fields += 1;
        values[fields] = segments[s].speed_d; fields += 1;
    }
    for (usz j = 0; j < n; j += 1) {
        values[fields] = completion[j].n; fields += 1;
        values[fields] = completion[j].d; fields += 1;
    }
    usz bytes = 8*fields;
    if (output == null || capacity < bytes) return -2;
    char[MAX_OUTPUT] staged = zeroed;
    for (usz i = 0; i < fields; i += 1) oa_put(&staged[0],8*i,values[i]);
    for (usz i = 0; i < bytes; i += 1) output[i] = staged[i];
    return (long)bytes;
}
