module number_of_boolean_functions_sequence;

fn long number_of_boolean_functions_sequence(long index) @export("number_of_boolean_functions_sequence") {
    if (index < 0 || index > 5) return -1;
    long value = 2;
    for (long i = 0; i < index; i += 1) value *= value;
    return value;
}
