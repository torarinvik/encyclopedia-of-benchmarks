module palindrome_linked_list;

// Compare the linked-list value sequence from both ends without mutation.
fn long palindrome_linked_list(long* values, usz length) @export("palindrome_linked_list") {
    if (length > 100000) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 0 || values[index] > 9) return -1;
    }

    usz left = 0;
    usz right = length;
    while (left < right) {
        right--;
        if (values[left] != values[right]) return 0;
        left++;
    }
    return 1;
}
