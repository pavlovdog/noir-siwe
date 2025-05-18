// Copied from https://github.com/madztheo/noir-string-utils
// Does not work when using as a dependency

global ZERO_INDEX: u8 = 48;
global NINE_INDEX: u8 = 57;

pub fn to_uint_slice<let N: u32>(s: [u8; N], start: u64, end: u64) -> u64 {
    assert(start <= end, "Start index must be less than or equal to end index");
    assert(end <= N as u64, "End index out of bounds");

    let mut result = 0;

    for i in 0..N as u64 {
        if (i >= start) & (i < end) {
            let digit = digit_at(s, i);
            result = result * 10 + digit as u64;
        }
    }

    result
}

fn digit_at<let N: u32>(s: [u8; N], index: u64) -> u8 {
    let byte = s[index];
    assert((byte >= ZERO_INDEX) & (byte <= NINE_INDEX), "Character is not a digit");
    byte - ZERO_INDEX
}
