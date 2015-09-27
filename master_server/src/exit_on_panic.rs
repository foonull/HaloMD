#![macro_use]

// Shuts down the process if this struct's destructor is called as a result of a panic.
pub struct ExitOnPanic;
impl Drop for ExitOnPanic {
    fn drop(&mut self) {
        use std::{thread,process};
        if thread::panicking() {
            process::exit(1); //Goodbye, cruel world!
        }
    }
}

// This macro takes an expression. If a panic occurs, then the process exits. Otherwise, the result of the expression is returned.
macro_rules! exit_on_panic {
    ($x:expr) => (
        {
            let _eop_struct = exit_on_panic::ExitOnPanic;
            $x
        }
    )
}
