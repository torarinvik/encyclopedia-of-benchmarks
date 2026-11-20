module jacobson_matthews_latin_square_chain;

const usz MAX_N = 4;
const usz MAX_CELLS = 64;
const usz MAX_MOVES = 48;
const usz MAX_WORDS = 66;

struct Move { usz i, j, k, ip, jp, kp; }

fn usz at(usz n, usz i, usz j, usz k) { return (i * n + j) * n + k; }

fn bool select_move(long* tensor, usz n, usz choice, Move* selected) {
    Move[MAX_MOVES] moves = zeroed;
    usz defects = 0, pi = 0, pj = 0, pk = 0, count = 0;
    for (usz i = 0; i < n; i++) for (usz j = 0; j < n; j++) for (usz k = 0; k < n; k++) {
        if (tensor[at(n, i, j, k)] == -1) { defects++; pi=i; pj=j; pk=k; }
    }
    if (defects > 1) return false;
    if (defects == 1) {
        for (usz ip = 0; ip < n; ip++) for (usz jp = 0; jp < n; jp++) for (usz kp = 0; kp < n; kp++) {
            if (ip != pi && jp != pj && kp != pk && tensor[at(n, pi, pj, kp)] == 1 &&
                tensor[at(n, pi, jp, pk)] == 1 && tensor[at(n, ip, pj, pk)] == 1)
                moves[count++] = Move{pi,pj,pk,ip,jp,kp};
        }
        if (count != 8) return false;
    } else {
        for (usz i = 0; i < n; i++) for (usz j = 0; j < n; j++) for (usz k = 0; k < n; k++) {
            if (tensor[at(n,i,j,k)] != 0) continue;
            usz ip=n, jp=n, kp=n;
            for (usz x = 0; x < n; x++) if (tensor[at(n,x,j,k)] == 1) ip=x;
            for (usz x = 0; x < n; x++) if (tensor[at(n,i,x,k)] == 1) jp=x;
            for (usz x = 0; x < n; x++) if (tensor[at(n,i,j,x)] == 1) kp=x;
            if (ip == n || jp == n || kp == n) return false;
            moves[count++] = Move{i,j,k,ip,jp,kp};
        }
        if (count != n*n*n-n*n) return false;
    }
    if (choice >= count) return false;
    *selected = moves[choice];
    return true;
}

fn bool apply_choice(long* tensor, usz n, usz choice) {
    Move m;
    if (!select_move(tensor,n,choice,&m)) return false;
    tensor[at(n,m.i,m.j,m.k)]++;
    tensor[at(n,m.ip,m.jp,m.k)]++;
    tensor[at(n,m.ip,m.j,m.kp)]++;
    tensor[at(n,m.i,m.jp,m.kp)]++;
    tensor[at(n,m.ip,m.j,m.k)]--;
    tensor[at(n,m.i,m.jp,m.k)]--;
    tensor[at(n,m.i,m.j,m.kp)]--;
    tensor[at(n,m.ip,m.jp,m.kp)]--;
    return true;
}

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset+byte]=(char)(bits>>(byte*8));
}

fn long jacobson_matthews_latin_square_chain(long* input, usz length, char* output,
    usz capacity) @export("jacobson_matthews_latin_square_chain") {
    if (input == null || length < 2 || length > 14) return -1;
    long n_value=input[0], steps_value=input[1];
    if (n_value < 2 || n_value > (long)MAX_N || steps_value < 0 || steps_value > 12 ||
        length != 2+(usz)steps_value) return -1;
    usz n=(usz)n_value, steps=(usz)steps_value;
    long[MAX_CELLS] tensor=zeroed;
    for (usz i=0;i<n;i++) for (usz j=0;j<n;j++) tensor[at(n,i,j,(i+j)%n)]=1;
    for (usz s=0;s<steps;s++) {
        if (input[2+s] < 0 || input[2+s] >= (long)MAX_MOVES ||
            !apply_choice(&tensor[0],n,(usz)input[2+s])) return -1;
    }
    usz words_count=2+n*n*n, output_bytes=words_count*8;
    if (output == null || capacity < output_bytes) return -2;
    long[MAX_WORDS] words=zeroed;
    words[0]=n_value; words[1]=steps_value;
    for (usz i=0;i<n*n*n;i++) words[2+i]=tensor[i];
    for (usz i=0;i<words_count;i++) write_i64_le(output,i*8,words[i]);
    return (long)output_bytes;
}
