module sock_merchant;

const usz MAX_LENGTH = 512;
const usz COLOR_COUNT = 4096;

fn long sock_merchant(long* colors, usz length) @export("sock_merchant")
{
    if (length > MAX_LENGTH) return -1;
    usz[COLOR_COUNT] counts;
    for (usz color = 0; color < COLOR_COUNT; color += 1) counts[color] = 0;
    for (usz i = 0; i < length; i += 1) {
        long value = colors[i];
        if (value < 0 || value >= (long)COLOR_COUNT) return -1;
        counts[(usz)value] += 1;
    }
    usz pairs = 0;
    for (usz color = 0; color < COLOR_COUNT; color += 1) pairs += counts[color] / 2;
    return (long)pairs;
}
