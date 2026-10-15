/// Return the logical complement on the Boolean 0/1 domain.
export fn not_gate(value: i64) i64 {
    return if (value == 0) 1 else 0;
}
