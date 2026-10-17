package modulo

import "core:c"

// Bounded unsigned modulo matching TheAlgorithms/Solidity Modulo.GetModulo.
@(export)
modulo :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != 2 do return -1
    a := values[0]
    b := values[1]
    if a < 0 || a > 4_294_967_295 || b < 1 || b > 4_294_967_295 do return -1
    return a % b
}
