module longest_valid_parentheses_stack;

const MAX_LENGTH = 4096;

// Track unmatched opening positions and the boundary before each valid segment.
fn long longest_valid_parentheses_stack(long* input, usz length)
    @export("longest_valid_parentheses_stack")
{
    if (length > MAX_LENGTH || (length != 0 && input == null)) return -1;
    for (usz index = 0; index < length; index++)
        if (input[index] != 40 && input[index] != 41) return -1;

    long[MAX_LENGTH + 1] unmatched;
    usz top = 0;
    unmatched[top] = -1;
    usz best = 0;
    for (usz index = 0; index < length; index++) {
        if (input[index] == 40) {
            top++;
            unmatched[top] = (long)index;
        } else {
            if (top == 0) {
                unmatched[0] = (long)index;
            } else {
                top--;
                usz start = (usz)unmatched[top];
                usz current = index - start;
                if (current > best) best = current;
            }
        }
    }
    return (long)best;
}
