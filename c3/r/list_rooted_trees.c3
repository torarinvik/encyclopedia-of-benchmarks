module list_rooted_trees;

const usz MAX_VERTICES = 7;
const usz MAX_SHAPES = 48;
const usz MAX_WIDTH = 15;
const usz MAX_CANDIDATES = 37;
const usz MAX_OUTPUT = 674;

struct Candidate {
    usz size;
    char* text;
}

struct Generator {
    char[8 * MAX_SHAPES * MAX_WIDTH] shapes;
    usz[8] counts;
    Candidate[MAX_CANDIDATES] candidates;
    usz candidate_count;
    usz target;
}

fn usz shape_offset(usz size, usz index) {
    return (size * MAX_SHAPES + index) * MAX_WIDTH;
}

fn char* shape_ptr(Generator* generator, usz size, usz index) {
    return &generator->shapes[shape_offset(size, index)];
}

fn bool text_less(char* left, char* right) {
    for (usz index = 0; index < MAX_WIDTH; index += 1) {
        if (left[index] != right[index]) return left[index] < right[index];
        if (left[index] == 0) return false;
    }
    return false;
}

fn void enumerate_multisets(Generator* generator, usz start,
                            usz remaining, char* children,
                            usz child_length) {
    if (remaining == 0) {
        usz index = generator->counts[generator->target];
        if (index >= MAX_SHAPES) return;
        char* shape = shape_ptr(generator, generator->target, index);
        shape[0] = '(';
        for (usz offset = 0; offset < child_length; offset += 1) {
            shape[offset + 1] = children[offset];
        }
        shape[child_length + 1] = ')';
        shape[child_length + 2] = 0;
        generator->counts[generator->target] = index + 1;
        return;
    }

    for (usz index = start; index < generator->candidate_count; index += 1) {
        Candidate candidate = generator->candidates[index];
        if (candidate.size > remaining) continue;
        usz encoded_length = 2 * candidate.size;
        for (usz offset = 0; offset < encoded_length; offset += 1) {
            children[child_length + offset] = candidate.text[offset];
        }
        enumerate_multisets(generator, index, remaining - candidate.size,
                            children, child_length + encoded_length);
    }
}

fn void sort_shapes(Generator* generator, usz size) {
    for (usz index = 1; index < generator->counts[size]; index += 1) {
        char[MAX_WIDTH] value = {};
        char* current = shape_ptr(generator, size, index);
        for (usz offset = 0; offset < MAX_WIDTH; offset += 1) {
            value[offset] = current[offset];
        }
        usz position = index;
        while (position > 0 &&
              text_less(&value[0], shape_ptr(generator, size, position - 1))) {
            char* destination = shape_ptr(generator, size, position);
            char* source = shape_ptr(generator, size, position - 1);
            for (usz offset = 0; offset < MAX_WIDTH; offset += 1) {
                destination[offset] = source[offset];
            }
            position -= 1;
        }
        char* destination = shape_ptr(generator, size, position);
        for (usz offset = 0; offset < MAX_WIDTH; offset += 1) {
            destination[offset] = value[offset];
        }
    }
}

fn void build_shapes(Generator* generator, usz maximum) {
    generator->counts[1] = 1;
    char* leaf = shape_ptr(generator, 1, 0);
    leaf[0] = '(';
    leaf[1] = ')';
    leaf[2] = 0;

    for (usz target = 2; target <= maximum; target += 1) {
        generator->target = target;
        generator->candidate_count = 0;
        for (usz size = 1; size < target; size += 1) {
            for (usz index = 0; index < generator->counts[size]; index += 1) {
                Candidate candidate;
                candidate.size = size;
                candidate.text = shape_ptr(generator, size, index);
                usz position = generator->candidate_count;
                while (position > 0 && text_less(candidate.text,
                        generator->candidates[position - 1].text)) {
                    generator->candidates[position] =
                        generator->candidates[position - 1];
                    position -= 1;
                }
                generator->candidates[position] = candidate;
                generator->candidate_count += 1;
            }
        }

        char[MAX_WIDTH] children = {};
        enumerate_multisets(generator, 0, target - 1, &children[0], 0);
        sort_shapes(generator, target);
    }
}

fn long list_rooted_trees(long* input, usz length, char* output,
                          usz capacity) @export("list_rooted_trees") {
    if (input == null || length != 1) return -1;
    long requested = input[0];
    if (requested < 1 || requested > (long)MAX_VERTICES) return -1;

    Generator generator = {};
    usz vertices = (usz)requested;
    build_shapes(&generator, vertices);

    uchar[MAX_OUTPUT] staged = {};
    usz count = generator.counts[vertices];
    staged[0] = (uchar)(count & 255);
    staged[1] = (uchar)((count >> 8) & 255);
    usz width = 2 * vertices;
    usz position = 2;
    for (usz index = 0; index < count; index += 1) {
        char* shape = shape_ptr(&generator, vertices, index);
        for (usz offset = 0; offset < width; offset += 1) {
            staged[position + offset] = (uchar)shape[offset];
        }
        position += width;
    }

    if (output == null || capacity < position) return -2;
    for (usz offset = 0; offset < position; offset += 1) {
        output[offset] = (char)staged[offset];
    }
    return (long)position;
}
