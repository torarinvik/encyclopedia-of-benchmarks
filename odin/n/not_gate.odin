package not_gate

// Return the logical complement on the Boolean 0/1 domain.
@(export)
not_gate :: proc "c" (value: i64) -> i64 {
    if value == 0 {
        return 1
    }
    return 0
}
