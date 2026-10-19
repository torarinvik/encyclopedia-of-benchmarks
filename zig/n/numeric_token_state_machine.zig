// Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
// Apache-2.0 licensed upstream kernel, bounded variant; modifications made.
const MAX_TEXT: usize = 96;

fn scanText(text: *const [MAX_TEXT]u8, n: usize, finals: *[8]u32, transitions: *[8]u32) void {
    var pos: usize = 0;
    while (pos < n) {
        var state: usize = 0;
        while (pos < n and state != 1) {
            const ch = text[pos];
            if (ch == ',') { pos += 1; break; }
            const digit = ch >= '0' and ch <= '9';
            switch (state) {
                0 => { if (digit) {state=4;} else if (ch=='+' or ch=='-') {state=2;} else if (ch=='.') {state=5;} else {state=1;transitions[1]+=1;} transitions[0]+=1; },
                2 => { if (digit) {state=4;} else if (ch=='.') {state=5;} else {state=1;} transitions[2]+=1; },
                4 => { if (ch=='.') {state=5;transitions[4]+=1;} else if (!digit) {state=1;transitions[4]+=1;} },
                5 => { if (ch=='e' or ch=='E') {state=3;transitions[5]+=1;} else if (!digit) {state=1;transitions[5]+=1;} },
                3 => { if (ch=='+' or ch=='-') {state=6;} else {state=1;} transitions[3]+=1; },
                6 => { if (digit) {state=7;} else {state=1;} transitions[6]+=1; },
                7 => { if (!digit) {state=1;transitions[1]+=1;} },
                else => {},
            }
            pos += 1;
        }
        finals[state] += 1;
    }
}

export fn numeric_token_state_machine(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_TEXT+3) return -1;
    const raw_n=input[0]; const step=input[1]; const seed=input[2];
    if (raw_n<1 or raw_n>MAX_TEXT or length!=@as(usize,@intCast(raw_n))+3 or step<1 or step>16 or seed<1 or seed>255) return -1;
    const n: usize=@intCast(raw_n);
    var text: [MAX_TEXT]u8=@splat(0);
    for (0..n) |i| {if(input[3+i]<32 or input[3+i]>126)return -1;text[i]=@intCast(input[3+i]);}
    if(text[0]==',' or text[n-1]==',')return -1;
    for(1..n)|i|{if(text[i]==',' and text[i-1]==',')return -1;}
    var i: usize=0;
    while(i<n):(i+=@intCast(step)){const changed=text[i] ^ @as(u8,@intCast(seed));if(text[i]!=',' and (changed==',' or changed==0))return -1;}
    var finals: [8]u32=@splat(0); var transitions: [8]u32=@splat(0);
    scanText(&text,n,&finals,&transitions);
    i=0;while(i<n):(i+=@intCast(step)){if(text[i]!=',')text[i]^=@intCast(seed);}
    scanText(&text,n,&finals,&transitions);
    i=0;while(i<n):(i+=@intCast(step)){if(text[i]!=',')text[i]^=@intCast(seed);}
    if(output==null or capacity<64)return -2;
    for(0..8)|s|{for(0..4)|b|{output[s*8+b]=@truncate(finals[s]>>@intCast(8*b));output[s*8+4+b]=@truncate(transitions[s]>>@intCast(8*b));}}
    return 64;
}
