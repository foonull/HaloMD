#![macro_use]

macro_rules! unwrap_option_or_bail {
    ($expr:expr, $bail_block:block) => (match $expr {
        Some(val) => val,
        None => $bail_block
    })
}

macro_rules! unwrap_result_or_bail {
    ($expr:expr, $bail_block:block) => (match $expr {
        Ok(val) => val,
        Err(err) => { println!("Error: {}", err); $bail_block }
    })
}
