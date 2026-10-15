module is_srilankan_phone_number;

fn long is_srilankan_phone_number(long* phone, usz length) @export("is_srilankan_phone_number")
{
    if (phone == null || length == 0 || length > 15) return -1;
    for (usz i = 0; i < length; i++) {
        if (phone[i] < 0 || phone[i] > 127) return -1;
    }

    usz prefix_length;
    if (phone[0] == '0') {
        if (length >= 4 && phone[1] == '0' && phone[2] == '9' && phone[3] == '4') {
            prefix_length = 4;
        } else {
            prefix_length = 1;
        }
    } else if (length >= 2 && phone[0] == '9' && phone[1] == '4') {
        prefix_length = 2;
    } else if (length >= 3 && phone[0] == '+' && phone[1] == '9' && phone[2] == '4') {
        prefix_length = 3;
    } else {
        return 0;
    }

    usz cursor = prefix_length;
    if (cursor + 2 > length || phone[cursor] != '7') return 0;
    cursor += 1;
    long provider = phone[cursor];
    cursor += 1;
    if (provider != '0' && provider != '1' && provider != '2' && provider != '4' &&
        provider != '5' && provider != '6' && provider != '7' && provider != '8') return 0;

    usz end = length;
    if (phone[end - 1] == '\n') end -= 1;
    usz remaining = end - cursor;
    if (remaining == 8 && (phone[cursor] == '-' || phone[cursor] == ' ')) {
        cursor += 1;
    } else if (remaining != 7) {
        return 0;
    }
    for (usz i = 0; i < 7; i++) {
        if (phone[cursor + i] < '0' || phone[cursor + i] > '9') return 0;
    }
    return 1;
}
