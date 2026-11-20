from std.ffi import c_size_t

const FLR_MAX_N: usize = 5
const FLR_MAX_F: usize = 5
const FLR_MAX_Q: usize = 8
const FLR_MAX_P: usize = 10
const FLR_MAX_PARSEABLE: usize = 128
const FLR_MAX_OUTPUT: usize = 192

def flr_put(value: i64, output: mutable view[u8], offset: usize) -> void:
    bits: u64 = value.u64()
    for byte in range(8):
        output[offset + byte] <- ((bits >> (byte * 8)) & 255).u8()

def flr_cost(n: usize, f: usize, p: usize, d: i64&, demand: i64&,
        assignment: i64&, fee: i64&, mask: u64) -> i64:
    total: mutable i64 = 0
    for s in range(f):
        if (mask & (1u64 << s)) != 0: total <- total + fee[s]
    for j in range(n):
        total <- total + demand[j] * d[j * p + n + assignment[j].usize()]
    total

def facility_location_randomized_add_delete_many(input: i64&, length: usize,
        output: mutable u8&, capacity: usize) -> i64 @export("facility_location_randomized_add_delete_many"):
    if input.is_null() or length < 12 or length > FLR_MAX_PARSEABLE: return -1
    n64: i64 = input[0]
    f64: i64 = input[1]
    q64: i64 = input[2]
    raw_mask: i64 = input[3]
    if n64 < 1 or n64 > 5 or f64 < 1 or f64 > 5 or q64 < 1 or q64 > 8 or raw_mask <= 0 or raw_mask.u64() >= (1u64 << f64.usize()): return -1
    n: usize = n64.usize()
    f: usize = f64.usize()
    q: usize = q64.usize()
    p: usize = n + f
    if length != 4 + 2*n + p*p + f + q: return -1
    input_view: view[i64] = input[0:length]
    var mask: mutable u64 = raw_mask.u64()
    var assignment: mutable i64[5] = zeroed
    var demand: mutable i64[5] = zeroed
    var d: mutable i64[100] = zeroed
    var fee: mutable i64[5] = zeroed
    var tape: mutable i64[8] = zeroed
    pos: mutable usize = 4
    for j in range(n):
        assignment[j] <- input_view[pos]
        if assignment[j] < 0 or assignment[j] >= f64 or (mask & (1u64 << assignment[j].usize())) == 0: return -1
        pos <- pos + 1
    for j in range(n):
        demand[j] <- input_view[pos]
        if demand[j] < 1 or demand[j] > 10: return -1
        pos <- pos + 1
    for i in range(p):
        for j in range(p):
            value: i64 = input_view[pos]
            if value < 0 or value > 1000: return -1
            d[i*p+j] <- value
            pos <- pos + 1
    for i in range(p):
        if d[i*p+i] != 0: return -1
        for j in range(p):
            if i != j and d[i*p+j] == 0: return -1
            if d[i*p+j] != d[j*p+i]: return -1
            for k in range(p):
                if d[i*p+j] > d[i*p+k] + d[k*p+j]: return -1
    for s in range(f):
        fee[s] <- input_view[pos]
        if fee[s] < 0 or fee[s] > 1000: return -1
        pos <- pos + 1
    for t in range(q):
        tape[t] <- input_view[pos]
        if tape[t] < 0 or tape[t] >= f64: return -1
        pos <- pos + 1

    var trace_cost: mutable i64[8] = zeroed
    var trace_accept: mutable i64[8] = zeroed
    current: mutable i64 = flr_cost(n, f, p, d, demand, assignment, fee, mask)
    accepted_count: mutable i64 = 0
    for step in range(q):
        candidate: usize = tape[step].usize()
        bit: u64 = 1u64 << candidate
        did: mutable i64 = 0
        if (mask & bit) == 0:
            var closer: mutable bool[5] = zeroed
            gain: mutable i64 = -fee[candidate]
            for j in range(n):
                old: usize = assignment[j].usize()
                if d[j*p+n+candidate] < d[j*p+n+old]:
                    closer[j] <- true
                    gain <- gain + demand[j] * (d[j*p+n+old] - d[j*p+n+candidate])
            drop: mutable u64 = 0
            for s in range(f):
                if (mask & (1u64 << s)) != 0:
                    center_gain: mutable i64 = fee[s]
                    for j in range(n):
                        if assignment[j].usize() == s and not closer[j]:
                            center_gain <- center_gain + demand[j] * (d[j*p+n+s] - d[j*p+n+candidate])
                    if center_gain > 0:
                        drop <- drop | (1u64 << s)
                        gain <- gain + center_gain
            if gain > 0:
                mask <- (mask | bit) & ~drop
                for j in range(n):
                    if closer[j] or (drop & (1u64 << assignment[j].usize())) != 0:
                        assignment[j] <- candidate.i64()
                current <- flr_cost(n, f, p, d, demand, assignment, fee, mask)
                did <- 1
                accepted_count <- accepted_count + 1
        trace_cost[step] <- current
        trace_accept[step] <- did

    output_bytes: usize = 8 * (2*q + 3 + n)
    if output.is_null() or capacity < output_bytes: return -2
    output_view: mutable view[u8] = output[0:output_bytes]
    pos <- 0
    for t in range(q):
        flr_put(trace_cost[t], output_view, pos)
        pos <- pos + 8
    for t in range(q):
        flr_put(trace_accept[t], output_view, pos)
        pos <- pos + 8
    flr_put(current, output_view, pos); pos <- pos + 8
    flr_put(mask.i64(), output_view, pos); pos <- pos + 8
    for j in range(n):
        flr_put(assignment[j], output_view, pos)
        pos <- pos + 8
    flr_put(accepted_count, output_view, pos)
    (pos + 8).i64()
