module not_gate

// Return the logical complement on the Boolean 0/1 domain.
@[export: 'not_gate']
pub fn not_gate(value i64) i64 {
    return if value == 0 { i64(1) } else { i64(0) }
}
