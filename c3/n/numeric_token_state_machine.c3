module numeric_token_state_machine;
// Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
// Apache-2.0 licensed upstream kernel, bounded variant; modifications made.
const usz MAX_TEXT = 96;

fn void scan_text(char* text, usz n, uint* finals, uint* transitions) {
    usz pos = 0;
    while (pos < n) {
        usz state = 0;
        while (pos < n && state != 1) {
            char ch = text[pos];
            if (ch == ',') { pos += 1; break; }
            bool digit = ch >= '0' && ch <= '9';
            switch (state) {
                case 0: if (digit) state=4; else if (ch=='+' || ch=='-') state=2; else if (ch=='.') state=5; else {state=1;transitions[1]++;} transitions[0]++;
                case 2: if (digit) state=4; else if (ch=='.') state=5; else state=1; transitions[2]++;
                case 4: if (ch=='.') {state=5;transitions[4]++;} else if (!digit) {state=1;transitions[4]++;}
                case 5: if (ch=='e'||ch=='E') {state=3;transitions[5]++;} else if (!digit) {state=1;transitions[5]++;}
                case 3: if (ch=='+'||ch=='-') state=6; else state=1; transitions[3]++;
                case 6: if (digit) state=7; else state=1; transitions[6]++;
                case 7: if (!digit) {state=1;transitions[1]++;}
                default: break;
            }
            pos += 1;
        }
        finals[state]++;
    }
}

fn long numeric_token_state_machine(long* input, usz length, char* output, usz capacity)
    @export("numeric_token_state_machine") {
    if (input == null || length < 4 || length > MAX_TEXT + 3) return -1;
    long raw_n=input[0], step=input[1], seed=input[2];
    if (raw_n < 1 || raw_n > (long)MAX_TEXT || length != (usz)(raw_n+3) || step < 1 || step > 16 || seed < 1 || seed > 255) return -1;
    usz n=(usz)raw_n;
    char[MAX_TEXT] text;
    for (usz i=0;i<n;i++) {if(input[3+i]<32||input[3+i]>126)return -1;text[i]=(char)input[3+i];}
    if(text[0]==','||text[n-1]==',')return -1;
    for(usz i=1;i<n;i++)if(text[i]==','&&text[i-1]==',')return -1;
    for(usz i=0;i<n;i+=(usz)step)if(text[i]!=','&&((((uint)text[i]^(uint)seed)==(uint)',')||((uint)text[i]^(uint)seed)==0))return -1;
    uint[8] finals; uint[8] transitions;
    for(usz i=0;i<8;i++){finals[i]=0;transitions[i]=0;}
    scan_text(&text[0],n,&finals[0],&transitions[0]);
    for(usz i=0;i<n;i+=(usz)step)if(text[i]!=',')text[i]=(char)((uint)text[i]^(uint)seed);
    scan_text(&text[0],n,&finals[0],&transitions[0]);
    for(usz i=0;i<n;i+=(usz)step)if(text[i]!=',')text[i]=(char)((uint)text[i]^(uint)seed);
    if(output==null||capacity<64)return -2;
    for(usz i=0;i<8;i++)for(usz b=0;b<4;b++){output[i*8+b]=(char)(finals[i]>>(b*8));output[i*8+4+b]=(char)(transitions[i]>>(b*8));}
    return 64;
}
