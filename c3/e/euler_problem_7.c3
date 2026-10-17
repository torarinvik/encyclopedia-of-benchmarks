module euler_problem_7;

const usz SIEVE_LIMIT = 1000000;
const usz MAX_VALID_INPUT_LENGTH = 1;
const usz MAX_PARSEABLE_INPUT_LENGTH = 2;
const long MAX_ORDINAL = 10001;

fn long euler_problem_7(long* input, usz length) @export("euler_problem_7") {
    if (input == null || length < MAX_VALID_INPUT_LENGTH || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (length != MAX_VALID_INPUT_LENGTH || input[0] < 1 || input[0] > MAX_ORDINAL) return -1;

    bool[SIEVE_LIMIT] composite;
    for (usz index = 0; index < SIEVE_LIMIT; ++index) composite[index] = false;
    long count = 0;
    for (usz candidate = 2; candidate < SIEVE_LIMIT; ++candidate) {
        if (!composite[candidate]) {
            count++;
            if (count == input[0]) return (long)candidate;
            for (usz multiple = candidate * 2; multiple < SIEVE_LIMIT; multiple += candidate)
                composite[multiple] = true;
        }
    }
    return -1;
}
