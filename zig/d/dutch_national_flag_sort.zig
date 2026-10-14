/// Dutch national flag sort for values restricted to 0, 1, and 2.
export fn dutch_national_flag_sort(values: [*]i64, length: usize) void {
    var low: usize = 0;
    var middle: usize = 0;
    var high = length;
    while (middle < high) {
        if (values[middle] == 0) {
            const temporary = values[low];
            values[low] = values[middle];
            values[middle] = temporary;
            low += 1;
            middle += 1;
        } else if (values[middle] == 1) {
            middle += 1;
        } else {
            high -= 1;
            const temporary = values[middle];
            values[middle] = values[high];
            values[high] = temporary;
        }
    }
}
