module exchange_sort;

fn void exchange_sort(long* values, usz length) @export("exchange_sort")
{
    if (length < 2) return;
    usz last = length - 1;
    for (usz first = 0; first < last; first++) {
        for (usz other = first + 1; other < length; other++) {
            if (values[other] < values[first]) {
                long temporary = values[first];
                values[first] = values[other];
                values[other] = temporary;
            }
        }
    }
}
