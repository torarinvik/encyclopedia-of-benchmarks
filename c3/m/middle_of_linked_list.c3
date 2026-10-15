module middle_of_linked_list;

const MAX_NODES = 100000;

fn long middle_of_linked_list(long* next, usz length) @export("middle_of_linked_list") {
    if (length > MAX_NODES || (length != 0 && next == null)) return -2;
    for (usz index = 0; index < length; index++) {
        if (next[index] < -1 || next[index] >= (long)length) return -2;
    }
    if (length == 0) return -1;

    long slow = 0;
    long fast = 0;
    while (fast >= 0) {
        long first = next[(usz)fast];
        if (first < 0) break;
        slow = next[(usz)slow];
        fast = next[(usz)first];
        if (slow == fast) return -2;
    }

    slow = 0;
    fast = 0;
    while (fast >= 0) {
        long first = next[(usz)fast];
        if (first < 0) break;
        slow = next[(usz)slow];
        fast = next[(usz)first];
    }
    return slow;
}
