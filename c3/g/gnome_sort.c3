module gnome_sort;

fn void gnome_sort(long* values, usz length) @export("gnome_sort")
{
    if (length < 2) return;
    usz position = 1;
    while (position < length) {
        if (values[position] >= values[position - 1]) {
            position++;
        } else {
            long temporary = values[position - 1];
            values[position - 1] = values[position];
            values[position] = temporary;
            if (position > 1) position--;
            else position = 1;
        }
    }
}
