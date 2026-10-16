module is_valid_email_address;

fn bool ascii_letter(long value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

fn bool ascii_digit(long value) {
    return value >= '0' && value <= '9';
}

fn bool local_special(long value) {
    return value == '!' || value == '#' || value == '$' || value == '%' || value == '&' ||
        value == '\'' || value == '(' || value == ')' || value == '*' || value == '+' ||
        value == '-' || value == '.' || value == '/' || value == '=' || value == '?' ||
        value == '^' || value == '_' || value == '`' || value == '{' || value == '|' ||
        value == '}' || value == '~';
}

fn bool local_allowed(long value) {
    return ascii_letter(value) || ascii_digit(value) || local_special(value);
}

fn bool domain_allowed(long value) {
    return ascii_letter(value) || ascii_digit(value) || value == '.' || value == '-';
}

fn long is_valid_email_address(long* values, usz length) @export("is_valid_email_address") {
    if (length > 320) return 0;
    if (length != 0 && values == null) return -1;
    for (usz i = 0; i < length; i++) if (values[i] < 0 || values[i] > 0x10ffff) return -1;

    usz at = length;
    for (usz i = 0; i < length; i++) {
        if (values[i] == '@') {
            if (at != length) return 0;
            at = i;
        }
    }
    if (at == length) return 0;

    usz domain_start = at + 1;
    if (at > 64 || length - domain_start > 255) return 0;
    for (usz i = 0; i < at; i++) {
        long value = values[i];
        if (!local_allowed(value)) return 0;
        if (value == '.' && (i == 0 || i + 1 == at || values[i - 1] == '.')) return 0;
    }
    for (usz i = domain_start; i < length; i++) {
        long value = values[i];
        if (!domain_allowed(value)) return 0;
        if (value == '-' && i == domain_start) return 0;
        if (value == '.' && (i == domain_start || i + 1 == length || values[i - 1] == '.')) return 0;
    }
    return 1;
}
