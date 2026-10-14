module dutch_national_flag_sort;

fn void dutch_national_flag_sort(long* values, usz length) @export("dutch_national_flag_sort")
{
    usz low = 0;
    usz middle = 0;
    usz high = length;
    while (middle < high) {
        if (values[middle] == 0) {
            long temporary = values[low];
            values[low] = values[middle];
            values[middle] = temporary;
            low++;
            middle++;
        } else if (values[middle] == 1) {
            middle++;
        } else {
            high--;
            long temporary = values[middle];
            values[middle] = values[high];
            values[high] = temporary;
        }
    }
}
