module tilingproblem;

fn long tilingproblem(long* input, usz length) @export("tilingproblem") {
    if (input == null || length != 1 || input[0] < 0 || input[0] > 91) return -1;
    long previous=1,current=1;
    for(long width=2;width<=input[0];width++){long next=previous+current;previous=current;current=next;}
    return current;
}
