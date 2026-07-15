uniffi::setup_scaffolding!();

#[uniffi::export]
fn apply_display(brightness: u8, red: u8, green: u8, blue: u8) -> bool {
    red_level::apply_display(brightness, [red, green, blue]).is_ok()
}

#[uniffi::export]
fn start_display_daemon(brightness: u8, red: u8, green: u8, blue: u8) -> bool {
    red_level::start_daemon(brightness, [red, green, blue]).is_ok()
}

#[uniffi::export]
fn stop_display_daemon() -> bool {
    red_level::stop_daemon().is_ok()
}

#[uniffi::export]
fn reset_display() -> bool {
    red_level::reset_display().is_ok()
}
