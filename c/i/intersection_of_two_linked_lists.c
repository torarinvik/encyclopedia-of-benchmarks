/* Find the first shared node identity by switching traversal heads. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LIST_LENGTH 1024
#define MAX_INPUT_LENGTH (2 + 2 * MAX_LIST_LENGTH)

int64_t intersection_of_two_linked_lists(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -2;
    const int64_t first_length_value = input[0], second_length_value = input[1];
    if (first_length_value < 0 || first_length_value > MAX_LIST_LENGTH ||
        second_length_value < 0 || second_length_value > MAX_LIST_LENGTH) return -2;
    const size_t first_length = (size_t)first_length_value;
    const size_t second_length = (size_t)second_length_value;
    if (length != 2 + first_length + second_length) return -2;
    for (size_t index = 2; index < length; ++index)
        if (input[index] < 0 || input[index] > INT32_MAX) return -2;
    if (first_length == 0 || second_length == 0) return -1;

    size_t first_position = 0, second_position = 0;
    int first_on_first_list = 1, second_on_first_list = 0;
    for (size_t step = 0; step <= first_length + second_length; ++step) {
        const size_t first_base = first_on_first_list ? 2 : 2 + first_length;
        const size_t first_source_length = first_on_first_list ? first_length : second_length;
        const size_t second_base = second_on_first_list ? 2 : 2 + first_length;
        const size_t second_source_length = second_on_first_list ? first_length : second_length;
        const int64_t first_node = input[first_base + first_position];
        const int64_t second_node = input[second_base + second_position];
        if (first_node == second_node) return first_node;

        ++first_position;
        ++second_position;
        const int first_is_null = first_position == first_source_length;
        const int second_is_null = second_position == second_source_length;
        if (first_is_null && second_is_null) return -1;
        if (first_is_null) { first_on_first_list = !first_on_first_list; first_position = 0; }
        if (second_is_null) { second_on_first_list = !second_on_first_list; second_position = 0; }
    }
    return -1;
}
