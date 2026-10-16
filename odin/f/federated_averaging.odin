package federated_averaging
import "core:c"

@(export)
federated_averaging :: proc "c"(input: [^]i64, length: c.size_t) -> f64 {
    invalid: f64 = -1.0e300
    if input == nil || length < 3 || length > 17 do return invalid
    clients := input[0]
    if clients < 1 || clients > 8 || length != c.size_t(1 + 2 * clients) do return invalid
    total: f64 = 0
    for i := i64(0); i < clients; i += 1 {
        weight := input[1 + i]
        if weight < 0 || weight > 1000 do return invalid
        total += f64(weight)
    }
    if total <= 0 do return invalid
    result: f64 = 0
    for i := i64(0); i < clients; i += 1 {
        value := input[1 + clients + i]
        if value < -1000 || value > 1000 do return invalid
        normalized := f64(input[1 + i]) / total
        result += normalized * f64(value)
    }
    return result
}
