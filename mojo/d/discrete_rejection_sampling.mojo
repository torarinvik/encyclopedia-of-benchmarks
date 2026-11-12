from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_CATEGORIES = 8
alias MAX_SAMPLES = 8
alias MAX_ATTEMPTS = 32
alias MAX_INPUT_VALUES = 83

fn drs_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64) -> None:
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("discrete_rejection_sampling")
fn discrete_rejection_sampling(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT_VALUES:
        return -1
    let n_value = input[0]
    let samples_value = input[1]
    let attempts_value = input[2]
    if n_value < 1 or n_value > MAX_CATEGORIES or samples_value < 1 or samples_value > MAX_SAMPLES:
        return -1
    if attempts_value < 1 or attempts_value > MAX_ATTEMPTS:
        return -1
    let n = Int(n_value)
    let wanted = Int(samples_value)
    let attempts = Int(attempts_value)
    if length != c_size_t(3 + 2 * n + 2 * attempts):
        return -1

    var target = InlineArray[UInt64, MAX_CATEGORIES](fill=0)
    var proposal = InlineArray[UInt64, MAX_CATEGORIES](fill=0)
    var cumulative = InlineArray[UInt64, MAX_CATEGORIES](fill=0)
    var target_total: UInt64 = 0
    var proposal_total: UInt64 = 0
    for i in range(n):
        let weight = input[3 + i]
        let q_weight = input[3 + n + i]
        if weight < 1 or weight > 20 or q_weight < 1 or q_weight > 20:
            return -1
        target[i] = UInt64(weight)
        proposal[i] = UInt64(q_weight)
        target_total += target[i]
        proposal_total += proposal[i]
        cumulative[i] = proposal_total

    var envelope: UInt64 = 1
    for i in range(n):
        let numerator = target[i] * proposal_total
        let denominator = target_total * proposal[i]
        let ratio_ceiling = (numerator + denominator - 1) / denominator
        if ratio_ceiling > envelope:
            envelope = ratio_ceiling

    let tape_offset = 3 + 2 * n
    for attempt in range(attempts):
        let proposal_draw = input[tape_offset + 2 * attempt]
        let acceptance_draw = input[tape_offset + 2 * attempt + 1]
        if proposal_draw < 0 or UInt64(proposal_draw) >= proposal_total or acceptance_draw < 0:
            return -1
        var category = 0
        while cumulative[category] <= UInt64(proposal_draw):
            category += 1
        let acceptance_range = target_total * proposal[category] * envelope
        if UInt64(acceptance_draw) >= acceptance_range:
            return -1

    let output_bytes = 16 * wanted
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    var staged = InlineArray[Int64, 2 * MAX_SAMPLES](fill=0)
    var produced = 0
    var attempts_since_acceptance = 0
    for attempt in range(attempts):
        attempts_since_acceptance += 1
        let proposal_draw = UInt64(input[tape_offset + 2 * attempt])
        let acceptance_draw = UInt64(input[tape_offset + 2 * attempt + 1])
        var category = 0
        while cumulative[category] <= proposal_draw:
            category += 1
        if acceptance_draw < Int64(target[category] * proposal_total):
            staged[produced] = Int64(category)
            staged[produced + 1] = Int64(attempts_since_acceptance)
            produced += 2
            attempts_since_acceptance = 0
            if produced == 2 * wanted:
                break
    if produced != 2 * wanted:
        return -3
    for i in range(produced):
        drs_store_i64_le(output, 8 * i, staged[i])
    return Int64(output_bytes)
