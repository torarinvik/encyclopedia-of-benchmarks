package simple_blockchain

import "core:c"

MAX_INPUT :: 4096
MAX_PADDED :: 4160
K :: [64]u32{0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}

rotr :: proc "contextless" (x: u32, n: u32) -> u32 { return (x >> n) | (x << (32-n)) }
add32 :: proc "contextless" (a,b:u32)->u32{return u32((u64(a)+u64(b))&0xffff_ffff)}

@(export)
bc_sha256 :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
	if length>MAX_INPUT||(length>0&&input==nil) do return -1
	n:=int(length);for i:=0;i<n;i+=1{if input[i]<0||input[i]>255 do return -1}
	var padded:[MAX_PADDED]u8;for i:=0;i<MAX_PADDED;i+=1{padded[i]=0};for i:=0;i<n;i+=1{padded[i]=u8(input[i])};padded[n]=0x80
	blocks:=(n+9+63)/64;padded_length:=blocks*64;bit_length:=u64(n)*8;for i:=0;i<8;i+=1{padded[padded_length-1-i]=u8((bit_length>>(8*i))&255)}
	h:=[8]u32{0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
	for block:=0;block<blocks;block+=1{
		var w:[64]u32
		for i:=0;i<16;i+=1{p:=block*64+i*4;w[i]=(u32(padded[p])<<24)|(u32(padded[p+1])<<16)|(u32(padded[p+2])<<8)|u32(padded[p+3])}
		for i:=16;i<64;i+=1{x:=w[i-15];y:=w[i-2];s0:=rotr(x,7)^rotr(x,18)^(x>>3);s1:=rotr(y,17)^rotr(y,19)^(y>>10);w[i]=add32(add32(add32(s1,w[i-7]),s0),w[i-16])}
		a,b,cc,d,e,f,g,hh:=h[0],h[1],h[2],h[3],h[4],h[5],h[6],h[7]
		for i:=0;i<64;i+=1{s1:=rotr(e,6)^rotr(e,11)^rotr(e,25);ch:=(e&f)^(~e&g);t1:=add32(add32(add32(add32(hh,s1),ch),K[i]),w[i]);s0:=rotr(a,2)^rotr(a,13)^rotr(a,22);maj:=(a&b)^(a&cc)^(b&cc);t2:=add32(s0,maj);hh=g;g=f;f=e;e=add32(d,t1);d=cc;cc=b;b=a;a=add32(t1,t2)}
		h[0]=add32(h[0],a);h[1]=add32(h[1],b);h[2]=add32(h[2],cc);h[3]=add32(h[3],d);h[4]=add32(h[4],e);h[5]=add32(h[5],f);h[6]=add32(h[6],g);h[7]=add32(h[7],hh)
	}
	if output==nil||capacity<32 do return -2
	for i:=0;i<8;i+=1{for byte:=0;byte<4;byte+=1{output[i*4+byte]=u8((h[i]>>(24-8*byte))&255)}}
	return 32
}


BC_MAX_VALUES :: 465
BC_MAX_CHAIN :: 8
BC_MAX_DATA :: 64
BC_MAX_HEADER :: 160
BC_NONCE_ATTEMPTS :: 4096
BC_MAX_OUTPUT :: 728

Block :: struct {
    timestamp_sec: i64,
    data: [BC_MAX_DATA]u8,
    data_length: int,
    previous_hash: [64]u8,
    previous_hash_length: int,
    nonce: i64,
    hash: [64]u8,
}

bc_append_decimal :: proc "contextless" (buffer: [^]i64, position_value: int, value_value: i64) -> int {
    digits: [20]i64
    count := 0
    value := value_value
    for {
        digits[count] = i64('0') + value % 10
        count += 1
        value /= 10
        if value == 0 do break
    }
    position := position_value
    for count > 0 {
        count -= 1
        buffer[position] = digits[count]
        position += 1
    }
    return position
}

bc_make_header :: proc "contextless" (index: int, block: ^Block, nonce: i64, header: [^]i64) -> int {
    length := bc_append_decimal(header, 0, i64(index))
    length = bc_append_decimal(header, length, block.timestamp_sec)
    header[length] = i64('.')
    length += 1
    header[length] = i64('0')
    length += 1
    for i := 0; i < block.data_length; i += 1 {
        header[length] = i64(block.data[i])
        length += 1
    }
    for i := 0; i < block.previous_hash_length; i += 1 {
        header[length] = i64(block.previous_hash[i])
        length += 1
    }
    return bc_append_decimal(header, length, nonce)
}

bc_to_hex :: proc "contextless" (digest: [^]u8, output: [^]u8) {
    hex := "0123456789abcdef"
    for i := 0; i < 32; i += 1 {
        byte := digest[i]
        output[2*i] = hex[byte >> 4]
        output[2*i+1] = hex[byte & 15]
    }
}

bc_compute_hash :: proc "contextless" (index: int, block: ^Block, nonce: i64, output: [^]u8) -> bool {
    header: [BC_MAX_HEADER]i64
    digest: [32]u8
    length := bc_make_header(index, block, nonce, &header[0])
    if bc_sha256(&header[0], c.size_t(length), &digest[0], c.size_t(32)) != 32 do return false
    bc_to_hex(&digest[0], output)
    return true
}

bc_has_prefix :: proc "contextless" (hash: [^]u8, difficulty: i64) -> bool {
    for i := 0; i < int(difficulty); i += 1 {
        if hash[i] != u8('0') do return false
    }
    return true
}

bc_is_valid :: proc "contextless" (blocks: [^]Block, chain_length: int, difficulty: i64) -> bool {
    for i := 1; i < chain_length; i += 1 {
        if blocks[i].previous_hash_length != 64 do return false
        for j := 0; j < 64; j += 1 {
            if blocks[i].previous_hash[j] != blocks[i-1].hash[j] do return false
        }
        if !bc_has_prefix(&blocks[i].hash[0], difficulty) do return false
        recomputed: [64]u8
        if !bc_compute_hash(i, &blocks[i], blocks[i].nonce, &recomputed[0]) do return false
        for j := 0; j < 64; j += 1 {
            if blocks[i].hash[j] != recomputed[j] do return false
        }
    }
    return true
}

bc_write_i64 :: proc "contextless" (output: [^]u8, position_value: int, value: i64) -> int {
    position := position_value
    bits := u64(value)
    for i := 0; i < 8; i += 1 {
        output[position] = u8((bits >> (8*i)) & 255)
        position += 1
    }
    return position
}

@(export)
simple_blockchain :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > BC_MAX_VALUES do return -1
    difficulty := input[0]
    chain_length_value := input[1]
    if difficulty < 1 || difficulty > 2 || chain_length_value < 1 || chain_length_value > BC_MAX_CHAIN do return -1
    chain_length := int(chain_length_value)
    max_timestamp: i64 = 2147483647
    if input[2] < 0 || input[2] > max_timestamp do return -1

    blocks: [BC_MAX_CHAIN]Block
    for i := 0; i < BC_MAX_CHAIN; i += 1 {
        blocks[i].timestamp_sec = 0
        blocks[i].data_length = 0
        blocks[i].previous_hash_length = 0
        blocks[i].nonce = 0
        for j := 0; j < BC_MAX_DATA; j += 1 do blocks[i].data[j] = 0
        for j := 0; j < 64; j += 1 { blocks[i].previous_hash[j] = 0; blocks[i].hash[j] = 0 }
    }
    blocks[0].timestamp_sec = input[2]
    genesis := [13]u8{71,101,110,101,115,105,115,32,66,108,111,99,107}
    for i := 0; i < 13; i += 1 do blocks[0].data[i] = genesis[i]
    blocks[0].data_length = 13
    blocks[0].previous_hash[0] = u8('0')
    blocks[0].previous_hash_length = 1

    cursor := 3
    for i := 1; i < chain_length; i += 1 {
        if cursor + 2 > int(length) do return -1
        timestamp_sec := input[cursor]
        data_length_value := input[cursor+1]
        cursor += 2
        if timestamp_sec < 0 || timestamp_sec > max_timestamp || data_length_value < 0 || data_length_value > BC_MAX_DATA do return -1
        data_length := int(data_length_value)
        if cursor + data_length > int(length) do return -1
        blocks[i].timestamp_sec = timestamp_sec
        blocks[i].data_length = data_length
        for j := 0; j < data_length; j += 1 {
            value := input[cursor+j]
            if value < 0 || value > 127 do return -1
            blocks[i].data[j] = u8(value)
        }
        cursor += data_length
    }
    if cursor != int(length) do return -1

    for i := 0; i < chain_length; i += 1 {
        if i > 0 {
            for j := 0; j < 64; j += 1 do blocks[i].previous_hash[j] = blocks[i-1].hash[j]
            blocks[i].previous_hash_length = 64
        }
        mined := false
        for nonce: i64 = 0; nonce < BC_NONCE_ATTEMPTS; nonce += 1 {
            candidate: [64]u8
            if !bc_compute_hash(i, &blocks[i], nonce, &candidate[0]) do return -1
            if bc_has_prefix(&candidate[0], difficulty) {
                blocks[i].nonce = nonce
                for j := 0; j < 64; j += 1 do blocks[i].hash[j] = candidate[j]
                mined = true
                break
            }
        }
        if !mined do return -3
    }

    valid: i64 = 0
    if bc_is_valid(&blocks[0], chain_length, difficulty) do valid = 1
    payload: [BC_MAX_OUTPUT]u8
    written := 0
    written = bc_write_i64(&payload[0], written, 0)
    written = bc_write_i64(&payload[0], written, chain_length_value)
    for i := 0; i < chain_length; i += 1 {
        written = bc_write_i64(&payload[0], written, i64(i))
        written = bc_write_i64(&payload[0], written, blocks[i].timestamp_sec)
        written = bc_write_i64(&payload[0], written, blocks[i].nonce)
        for j := 0; j < 64; j += 1 { payload[written] = blocks[i].hash[j]; written += 1 }
    }
    written = bc_write_i64(&payload[0], written, valid)
    if output == nil || output_capacity < c.size_t(written) do return -2
    for i := 0; i < written; i += 1 do output[i] = payload[i]
    return i64(written)
}
