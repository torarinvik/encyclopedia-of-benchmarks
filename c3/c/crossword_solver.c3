module crossword_solver;
const usz MAX_WORDS = 8;
const usz MAX_LEN = 8;

fn bool search(long* grid, usz rows, usz cols, long* words, usz* lens, usz* rem, usz count) {
    usz total = rows * cols; usz start = 0;
    while (start < total && grid[start] != 0) start++;
    if (start == total) return true;
    usz row = start / cols; usz col = start % cols;
    usz[8] current; for (usz i=0;i<count;i++) current[i]=rem[i];
    usz current_count = count;
    for (usz wi = 0; wi < count; wi++) {
        usz word = rem[wi]; usz n = lens[word];
        for (usz direction = 0; direction < 2; direction++) {
            bool vertical = direction == 0;
            if ((vertical && row + n > rows) || (!vertical && col + n > cols)) continue;
            bool valid = true;
            for (usz i = 0; i < n; i++) { usz cell = vertical ? (row+i)*cols+col : row*cols+col+i; if (grid[cell] != 0) valid = false; }
            if (!valid) continue;
            for (usz i = 0; i < n; i++) { usz cell = vertical ? (row+i)*cols+col : row*cols+col+i; grid[cell] = words[word*8+i]; }
            usz[8] next; usz next_count = 0; usz removed = 0;
            for (usz i = 0; i < current_count; i++) { if (current[i] == word) { removed = i; } else { next[next_count++] = current[i]; } }
            for (usz i = removed + 1; i < current_count; i++) current[i-1] = current[i];
            current_count--;
            if (search(&grid[0], rows, cols, words, lens, &next[0], next_count)) return true;
            for (usz i = 0; i < n; i++) { usz cell = vertical ? (row+i)*cols+col : row*cols+col+i; grid[cell] = 0; }
            current[current_count++] = word;
        }
    }
    return false;
}

fn long crossword_solver(long* input, usz length, char* output, usz capacity) @export("crossword_solver") {
    if (input == null || length < 3) return -1;
    long rv=input[0]; long cv=input[1]; long nv=input[2];
    if (rv<1 || rv>8 || cv<1 || cv>8 || nv<0 || nv>8) return -1;
    usz rows=(usz)rv; usz cols=(usz)cv; usz count=(usz)nv;
    if (length < 3+rows*cols) return -1;
    long[64] grid; for (usz i=0;i<rows*cols;i++) { long v=input[3+i]; if (v!=0 && v!=-1 && (v<65 || v>90)) return -1; grid[i]=v; }
    long[64] words; usz[8] lens; usz pos=3+rows*cols;
    for (usz w=0;w<count;w++) {
        if (pos>=length || input[pos]<1 || input[pos]>8) return -1;
        lens[w]=(usz)input[pos++]; if (lens[w]>length-pos) return -1;
        for (usz i=0;i<lens[w];i++) { long v=input[pos++]; if (v<65 || v>90) return -1; words[w*8+i]=v; }
        for (usz p=0;p<w;p++) { bool same=lens[p]==lens[w]; for (usz i=0;same && i<lens[w];i++) if(words[p*8+i]!=words[w*8+i]) same=false; if(same)return -1; }
    }
    if(pos!=length)return -1;
    usz[8] rem; for(usz i=0;i<count;i++) rem[i]=i;
    bool solved=search(&grid[0],rows,cols,&words[0],&lens[0],&rem[0],count);
    usz required=(1+rows*cols)*8; if(output==null || capacity<required)return -2;
    for(usz i=0;i<1+rows*cols;i++) { long value=i==0 ? (solved?1:0) : grid[i-1]; ulong bits=(ulong)value; for(usz b=0;b<8;b++) output[i*8+b]=(char)((bits>>(b*8))&255); }
    return (long)required;
}
