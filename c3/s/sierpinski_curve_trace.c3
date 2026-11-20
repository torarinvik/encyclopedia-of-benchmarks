const MAX_ORDER = 2;
const MAX_PARSEABLE_INPUT = 2;
const MAX_STACK = 64;

struct Frame { char symbol; char level; }

fn void push(Frame* stack, usz* top, char symbol, char level) {
    stack[*top].symbol = symbol;
    stack[*top].level = level;
    *top += 1;
}

fn usz emit_curve(char order, char* output) {
    Frame[MAX_STACK] stack = {};
    usz top = 0;
    usz written = 0;
    push(&stack, &top, (char)5, (char)0); push(&stack, &top, (char)3, order);
    push(&stack, &top, (char)7, (char)0); push(&stack, &top, (char)2, order);
    push(&stack, &top, (char)9, (char)0); push(&stack, &top, (char)1, order);
    push(&stack, &top, (char)11, (char)0); push(&stack, &top, (char)0, order);
    while (top != 0) {
        top -= 1;
        char symbol = stack[top].symbol;
        char level = stack[top].level;
        if (symbol >= 4) { output[written++] = (char)(symbol - 4); continue; }
        if (level == 0) continue;
        char child = level - 1;
        switch (symbol) {
            case 0:
                push(&stack,&top,(char)0,child); push(&stack,&top,(char)5,(char)0);
                push(&stack,&top,(char)3,child); push(&stack,&top,(char)12,(char)0);
                push(&stack,&top,(char)1,child); push(&stack,&top,(char)11,(char)0);
                push(&stack,&top,(char)0,child); break;
            case 1:
                push(&stack,&top,(char)1,child); push(&stack,&top,(char)11,(char)0);
                push(&stack,&top,(char)0,child); push(&stack,&top,(char)18,(char)0);
                push(&stack,&top,(char)2,child); push(&stack,&top,(char)9,(char)0);
                push(&stack,&top,(char)1,child); break;
            case 2:
                push(&stack,&top,(char)2,child); push(&stack,&top,(char)9,(char)0);
                push(&stack,&top,(char)1,child); push(&stack,&top,(char)16,(char)0);
                push(&stack,&top,(char)3,child); push(&stack,&top,(char)7,(char)0);
                push(&stack,&top,(char)2,child); break;
            default:
                push(&stack,&top,(char)3,child); push(&stack,&top,(char)7,(char)0);
                push(&stack,&top,(char)2,child); push(&stack,&top,(char)14,(char)0);
                push(&stack,&top,(char)0,child); push(&stack,&top,(char)5,(char)0);
                push(&stack,&top,(char)3,child); break;
        }
    }
    return written;
}

long sierpinski_curve_trace(long* input, usz length, char* output, usz capacity)
    @export("sierpinski_curve_trace") {
    if (input == null || length == 0 || length > MAX_PARSEABLE_INPUT) return -1;
    if (length != 1 || input[0] < 0 || input[0] > MAX_ORDER) return -1;
    usz order = (usz)input[0];
    usz required = 4;
    for (usz i = 0; i < order; i++) required *= 4;
    if (output == null || capacity < required) return -2;
    return (long)emit_curve((char)order, output);
}
