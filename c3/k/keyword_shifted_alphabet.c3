module keyword_shifted_alphabet;

const usz MAX_KEYWORD_LENGTH = 26;
const usz MAX_MESSAGE_LENGTH = 512;
const usz MAX_INPUT_LENGTH = 3 + MAX_KEYWORD_LENGTH + MAX_MESSAGE_LENGTH + 1;

fn long keyword_shifted_alphabet(long* input, usz length, u8* output,
                                 usz output_capacity)
    @export("keyword_shifted_alphabet")
{
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) { return -1; }
    long operation = input[0];
    long keyword_length_value = input[1];
    long message_length_value = input[2];
    if ((operation != 0 && operation != 1) || keyword_length_value < 1 || keyword_length_value > 26 ||
        message_length_value < 1 || message_length_value > (long)MAX_MESSAGE_LENGTH) { return -1; }
    usz keyword_length = (usz)keyword_length_value;
    usz message_length = (usz)message_length_value;
    if (length != 3 + keyword_length + message_length) { return -1; }

    u8[MAX_KEYWORD_LENGTH] keyword;
    u8[26] seen = zeroed;
    for (usz i = 0; i < keyword_length; i++) {
        long value = input[3 + i];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) { return -1; }
        u8 lower = (u8)(value >= 'A' && value <= 'Z' ? value + 32 : value);
        usz index = (usz)(lower - 'a');
        if (seen[index] != 0) { return -1; }
        seen[index] = 1;
        keyword[i] = lower;
    }
    u8[MAX_MESSAGE_LENGTH] message;
    for (usz i = 0; i < message_length; i++) {
        long value = input[3 + keyword_length + i];
        if (value < 0 || value > 127) { return -1; }
        message[i] = (u8)value;
    }

    u8[26] cipher_alphabet;
    u8[26] encode;
    u8[26] decode;
    usz cipher_length = 0;
    for (usz i = 0; i < keyword_length; i++) { cipher_alphabet[cipher_length++] = keyword[i]; }
    for (usz i = 0; i < 26; i++) {
        u8 letter = (u8)('a' + i);
        if (seen[i] == 0) { cipher_alphabet[cipher_length++] = letter; }
    }
    for (usz i = 0; i < 26; i++) {
        encode[i] = cipher_alphabet[i];
        decode[(usz)(cipher_alphabet[i] - 'a')] = (u8)('a' + i);
    }

    if (output_capacity < message_length || output == null) { return -2; }
    for (usz i = 0; i < message_length; i++) {
        u8 value = message[i];
        bool uppercase = value >= 'A' && value <= 'Z';
        usz index;
        if (uppercase) { index = (usz)(value - 'A'); }
        else if (value >= 'a' && value <= 'z') { index = (usz)(value - 'a'); }
        else { output[i] = value; continue; }
        u8 translated = operation == 0 ? encode[index] : decode[index];
        output[i] = uppercase ? (u8)(translated - ('a' - 'A')) : translated;
    }
    return (long)message_length;
}
