// use dep::std;
// use dep::string_utils;
// use dep::string_search;


global PREFIX: [u8; 26] = [25,69,116,104,101,114,101,117,109,32,83,105,103,110,101,100,32,77,101,115,115,97,103,101,58,10];

global MAX_LENGTH: u32 = 999;


fn getDigest<let N: u32>(
    message: [u8; N]
) -> [u8; 32] {
    // Convert message length to ASCII digits
    let message_len = message.len() as u32;
    let mut length_str: [u8; 3] = [0; 3];  // Max 3 digits for MAX_LENGTH of 500
    let mut length_str_len = 0;
    
    if message_len >= 100 {
        length_str[length_str_len] = (message_len / 100) as u8 + 48; // Add ASCII '0' (48)
        length_str_len += 1;
    }
    
    if message_len >= 10 {
        length_str[length_str_len] = ((message_len % 100) / 10) as u8 + 48;
        length_str_len += 1;
    }
    
    length_str[length_str_len] = (message_len % 10) as u8 + 48;
    length_str_len += 1;
    
    let mut prefixed_message: [u8; MAX_LENGTH] = [0; MAX_LENGTH];
    
    // Copy prefix
    for i in 0..26 {
        prefixed_message[i] = PREFIX[i];
    }
    
    // Copy length string
    for i in 0..length_str_len {
        prefixed_message[i + 26] = length_str[i];
    }
    
    // Copy message
    for i in 0..message.len() {
        prefixed_message[i + 26 + length_str_len] = message[i];
    }
    
    let prefixed_length = message.len() + 26 + length_str_len;

    let prefixed_digest = std::hash::keccak256(
        prefixed_message,
        prefixed_length as u32
    );

    prefixed_digest
}

