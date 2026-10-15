package electric_power

// Pinned electric_power formula over the benchmark's bounded integer-valued domain.
@(export)
electric_power :: proc "c" (voltage, current, power: f64) -> f64 {
    if voltage != voltage || current != current || power != power do return -1.0e300
    if voltage < -10000.0 || voltage > 10000.0 || current < -10000.0 || current > 10000.0 do return -1.0e300
    if power < 0.0 || power > 100000000.0 do return -1.0e300
    if voltage != f64(i64(voltage)) || current != f64(i64(current)) || power != f64(i64(power)) do return -1.0e300
    zeros := 0
    if voltage == 0.0 do zeros += 1
    if current == 0.0 do zeros += 1
    if power == 0.0 do zeros += 1
    if zeros != 1 do return -1.0e300
    if voltage == 0.0 do return power / current
    if current == 0.0 do return power / voltage
    product := voltage * current
    if product < 0.0 do return -product
    return product
}
