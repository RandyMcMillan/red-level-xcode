use clap::Parser;

#[derive(Parser, Debug)]
#[command(
    name = "red-level",
    about = "system-level dimming and color adjusting.",
    version
)]
struct Args {
    /// Brightness level in percentage (1 to 100)
    #[arg(short, long, default_value_t = 100)]
    brightness: u8,

    /// Use only the red channel
    #[arg(short, long, conflicts_with_all = ["red", "green", "blue", "levels"])]
    red_only: bool,

    /// Use only the red channel
    #[arg(long, conflicts_with_all = ["red_only", "green", "blue", "levels"])]
    red: bool,

    /// Use only the green channel
    #[arg(long, conflicts_with_all = ["red_only", "red", "blue", "levels"])]
    green: bool,

    /// Use only the blue channel
    #[arg(long, conflicts_with_all = ["red_only", "red", "green", "levels"])]
    blue: bool,

    /// Set red, green, and blue channel levels as percentages
    #[arg(
        long,
        value_names = ["RED", "GREEN", "BLUE"],
        num_args = 3,
        value_parser = clap::value_parser!(u8).range(0..=100),
        conflicts_with_all = ["red_only", "red", "green", "blue"]
    )]
    levels: Option<Vec<u8>>,

    /// Reset screen color and brightness back to standard system defaults
    #[arg(long)]
    reset: bool,

    /// Start the filter as a detached background process
    #[arg(long, conflicts_with_all = ["stop", "reset"])]
    start: bool,

    /// Stop the background filter process and restore the display
    #[arg(long, conflicts_with_all = ["start", "reset"])]
    stop: bool,

    #[arg(long, hide = true)]
    daemon: bool,
}

pub fn run() {
    let args = Args::parse();
    let channel_levels = resolve_channel_levels(&args);

    #[cfg(target_family = "unix")]
    {
        let start = args.start || (!args.daemon && !args.stop && !args.reset);
        if start {
            if let Err(error) = start_daemon(args.brightness, channel_levels) {
                eprintln!("Error: {error}");
                std::process::exit(1);
            }
            return;
        }
        if args.stop {
            if let Err(error) = stop_daemon() {
                eprintln!("Error: {error}");
                std::process::exit(1);
            }
            return;
        }
    }

    #[cfg(not(target_family = "unix"))]
    if args.start || args.stop {
        eprintln!("Error: Background process management is currently available only on Unix-like operating systems (macOS/Linux).");
        std::process::exit(1);
    }

    let clamped_brightness = args.brightness.clamp(1, 100);
    if args.reset {
        println!("Resetting screen filter and restoring original gamma curves...");
        if let Err(error) = reset_display() {
            eprintln!("Error: {error}");
            std::process::exit(1);
        }
    } else {
        println!(
            "Applying filter -> Brightness: {}% | RGB levels: {}% {}% {}%",
            clamped_brightness, channel_levels[0], channel_levels[1], channel_levels[2]
        );
        if let Err(error) = apply_display(args.brightness, channel_levels) {
            eprintln!("Error: {error}");
            std::process::exit(1);
        }
    }

    #[cfg(target_family = "unix")]
    {
        if args.daemon && !args.reset {
            loop {
                std::thread::park();
            }
        }

        #[cfg(feature = "ctrlc")]
        {
            if !args.reset {
                println!("Filter active. Press Ctrl+C to restore the display.");

                let _ = ctrlc::set_handler(move || {
                    println!("\nRestoring screen defaults...");
                    let _ = reset_display();
                    std::process::exit(0);
                });

                loop {
                    std::thread::park();
                }
            }
        }
    }
}

fn resolve_channel_levels(args: &Args) -> [u8; 3] {
    if let Some(levels) = &args.levels {
        return [levels[0], levels[1], levels[2]];
    }
    if args.red || args.red_only {
        return [100, 0, 0];
    }
    if args.green {
        return [0, 100, 0];
    }
    if args.blue {
        return [0, 0, 100];
    }
    [100; 3]
}

pub fn apply_display(brightness: u8, channel_levels: [u8; 3]) -> Result<(), String> {
    let clamped_brightness = brightness.clamp(1, 100);
    let scale = clamped_brightness as f64 / 100.0;
    let _channel_scales = channel_levels.map(|level| scale * level as f64 / 100.0);

    #[cfg(target_os = "windows")]
    {
        return windows_impl::apply_filter(_channel_scales);
    }

    #[cfg(any(target_os = "macos", all(target_os = "ios", target_abi = "macabi")))]
    {
        return macos_impl::apply_filter(_channel_scales);
    }

    #[cfg(target_os = "linux")]
    {
        return linux_impl::apply_filter(_channel_scales);
    }

    #[cfg(not(any(
        target_os = "windows",
        target_os = "macos",
        target_os = "linux",
        all(target_os = "ios", target_abi = "macabi")
    )))]
    {
        Err(String::from(
            "This application is currently only optimized for macOS, Windows, and Linux platforms.",
        ))
    }
}

pub fn reset_display() -> Result<(), String> {
    #[cfg(target_os = "windows")]
    {
        return windows_impl::apply_filter([1.0; 3]);
    }

    #[cfg(any(target_os = "macos", all(target_os = "ios", target_abi = "macabi")))]
    {
        return macos_impl::apply_filter([1.0; 3]);
    }

    #[cfg(target_os = "linux")]
    {
        return linux_impl::apply_filter([1.0; 3]);
    }

    #[cfg(not(any(
        target_os = "windows",
        target_os = "macos",
        target_os = "linux",
        all(target_os = "ios", target_abi = "macabi")
    )))]
    {
        Err(String::from(
            "This application is currently only optimized for macOS, Windows, and Linux platforms.",
        ))
    }
}

pub fn start_daemon(brightness: u8, channel_levels: [u8; 3]) -> Result<(), String> {
    #[cfg(target_family = "unix")]
    {
        return unix_daemon::start_daemon(brightness, channel_levels);
    }

    #[cfg(not(target_family = "unix"))]
    {
        let _ = brightness;
        let _ = channel_levels;
        Err(String::from(
            "Background process management is currently available only on Unix-like operating systems (macOS/Linux).",
        ))
    }
}

pub fn stop_daemon() -> Result<(), String> {
    #[cfg(target_family = "unix")]
    {
        return unix_daemon::stop_daemon();
    }

    #[cfg(not(target_family = "unix"))]
    {
        Err(String::from(
            "Background process management is currently available only on Unix-like operating systems (macOS/Linux).",
        ))
    }
}

// ==========================================
// UNIX BACKGROUND DAEMON MANAGEMENT (macOS / Linux)
// ==========================================
#[cfg(target_family = "unix")]
mod unix_daemon {
    use std::fs;
    use std::os::unix::process::CommandExt;
    use std::path::PathBuf;
    use std::process::{Command, Stdio};

    const SIGTERM: i32 = 15;
    const STOP_ATTEMPTS: usize = 40;
    const STOP_POLL_INTERVAL: std::time::Duration = std::time::Duration::from_millis(50);

    unsafe extern "C" {
        fn getuid() -> u32;
        fn kill(pid: i32, signal: i32) -> i32;
        fn setsid() -> i32;
    }

    fn pid_file() -> PathBuf {
        let uid = unsafe { getuid() };
        std::env::temp_dir().join(format!("red-level-{uid}.pid"))
    }

    fn read_running_pid() -> Option<i32> {
        let path = pid_file();
        let pid = fs::read_to_string(&path).ok()?.trim().parse().ok()?;
        if unsafe { kill(pid, 0) } == 0 {
            Some(pid)
        } else {
            let _ = fs::remove_file(path);
            None
        }
    }

    fn stop_process(pid: i32) -> Result<(), String> {
        if unsafe { kill(pid, SIGTERM) } != 0 {
            return Err(std::io::Error::last_os_error().to_string());
        }

        for _ in 0..STOP_ATTEMPTS {
            if unsafe { kill(pid, 0) } != 0 {
                return Ok(());
            }
            std::thread::sleep(STOP_POLL_INTERVAL);
        }

        Err(format!(
            "process {pid} did not stop within {} seconds",
            STOP_ATTEMPTS as f32 * STOP_POLL_INTERVAL.as_secs_f32()
        ))
    }

    fn remove_pid_file() -> Result<(), std::io::Error> {
        match fs::remove_file(pid_file()) {
            Ok(()) => Ok(()),
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(()),
            Err(error) => Err(error),
        }
    }

    fn restore_display() -> Result<(), String> {
        super::reset_display()
    }

    pub fn start_daemon(brightness: u8, channel_levels: [u8; 3]) -> Result<(), String> {
        if let Some(pid) = read_running_pid() {
            println!("Stopping existing red-level process {pid}...");
            stop_process(pid)
                .map_err(|error| format!("Failed to stop existing red-level process: {error}"))?;
            remove_pid_file()
                .map_err(|error| format!("Failed to remove the existing PID file: {error}"))?;
            restore_display()?;
        }

        let executable = match std::env::current_exe() {
            Ok(path) => path,
            Err(error) => {
                return Err(format!("Failed to locate red-level: {error}"));
            }
        };

        let mut command = Command::new(executable);
        command
            .arg("--daemon")
            .arg("--brightness")
            .arg(brightness.clamp(1, 100).to_string())
            .arg("--levels")
            .args(channel_levels.map(|level| level.to_string()))
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null());

        unsafe {
            command.pre_exec(|| {
                if setsid() == -1 {
                    return Err(std::io::Error::last_os_error());
                }
                Ok(())
            });
        }

        let child = match command.spawn() {
            Ok(child) => child,
            Err(error) => {
                return Err(format!(
                    "Failed to start red-level background daemon: {error}"
                ));
            }
        };

        if let Err(error) = fs::write(pid_file(), child.id().to_string()) {
            unsafe {
                kill(child.id() as i32, SIGTERM);
            }
            return Err(format!("Failed to save the red-level process ID: {error}"));
        }

        println!(
            "red-level daemon started successfully with process ID {}.",
            child.id()
        );
        Ok(())
    }

    pub fn stop_daemon() -> Result<(), String> {
        let Some(pid) = read_running_pid() else {
            return Err(String::from("red-level is not running in the background."));
        };

        stop_process(pid).map_err(|error| format!("Failed to stop red-level: {error}"))?;

        restore_display()?;

        if let Err(error) = remove_pid_file() {
            eprintln!("Warning: Failed to remove the red-level PID lockfile: {error}");
        }
        println!("red-level daemon stopped; the display has been restored.");
        Ok(())
    }
}

// ==========================================
// WINDOWS GDI ENGINE
// ==========================================
#[cfg(target_os = "windows")]
mod windows_impl {
    use std::ffi::c_void;
    use windows::Win32::Graphics::Gdi::GetDC;
    use windows::Win32::UI::ColorSystem::SetDeviceGammaRamp;

    pub fn apply_filter(channel_scales: [f64; 3]) -> Result<(), String> {
        let hdc = unsafe { GetDC(None) };
        if hdc.is_invalid() {
            let error = String::from("Failed to acquire display device context (HDC).");
            eprintln!("Error: {error}");
            return Err(error);
        }

        let mut ramp = [0u16; 768];

        for i in 0..256 {
            let val = (i as f64 / 255.0) * 65535.0;

            ramp[i] = (val * channel_scales[0]).round() as u16;
            ramp[i + 256] = (val * channel_scales[1]).round() as u16;
            ramp[i + 512] = (val * channel_scales[2]).round() as u16;
        }

        let result = unsafe { SetDeviceGammaRamp(hdc, ramp.as_ptr() as *const c_void) };
        if result.as_bool() {
            println!("System display filter applied successfully.");
            Ok(())
        } else {
            let error = String::from(
                "SetDeviceGammaRamp failed. Native HDR or administrative limits may apply.",
            );
            eprintln!("Error: {error}");
            Err(error)
        }
    }
}

// ==========================================
// macOS COREGRAPHICS FFI ENGINE
// ==========================================
#[cfg(any(target_os = "macos", all(target_os = "ios", target_abi = "macabi")))]
mod macos_impl {
    type CGDirectDisplayID = u32;
    type CGError = i32;

    #[link(name = "CoreGraphics", kind = "framework")]
    unsafe extern "C" {
        fn CGMainDisplayID() -> CGDirectDisplayID;
        fn CGSetDisplayTransferByTable(
            display: CGDirectDisplayID,
            table_size: u32,
            red_table: *const f32,
            green_table: *const f32,
            blue_table: *const f32,
        ) -> CGError;
    }

    pub fn apply_filter(channel_scales: [f64; 3]) -> Result<(), String> {
        let display_id = unsafe { CGMainDisplayID() };
        const TABLE_SIZE: usize = 256;

        let mut red_table = [0.0f32; TABLE_SIZE];
        let mut green_table = [0.0f32; TABLE_SIZE];
        let mut blue_table = [0.0f32; TABLE_SIZE];

        for i in 0..TABLE_SIZE {
            let val = i as f32 / (TABLE_SIZE - 1) as f32;

            red_table[i] = val * channel_scales[0] as f32;
            green_table[i] = val * channel_scales[1] as f32;
            blue_table[i] = val * channel_scales[2] as f32;
        }

        let result = unsafe {
            CGSetDisplayTransferByTable(
                display_id,
                TABLE_SIZE as u32,
                red_table.as_ptr(),
                green_table.as_ptr(),
                blue_table.as_ptr(),
            )
        };

        if result == 0 {
            println!("System display filter applied successfully.");
            Ok(())
        } else {
            let error = format!("CGSetDisplayTransferByTable failed with code {}.", result);
            eprintln!("Error: {error}");
            Err(error)
        }
    }
}

// ==========================================
// LINUX X11 / XRANDR FFI ENGINE
// ==========================================
#[cfg(target_os = "linux")]
mod linux_impl {
    use std::os::raw::{c_char, c_int, c_ulong, c_void};

    type Display = c_void;
    type Window = c_ulong;
    type RRAnyID = c_ulong;
    type RRCrtc = RRAnyID;

    #[repr(C)]
    struct XRRScreenResources {
        timestamp: c_ulong,
        config_timestamp: c_ulong,
        ncrtc: c_int,
        crtcs: *mut RRCrtc,
        noutput: c_int,
        outputs: *mut c_ulong,
        nmode: c_int,
        modes: *mut c_void,
    }

    #[repr(C)]
    struct XRRCrtcGamma {
        size: c_int,
        red: *mut u16,
        green: *mut u16,
        blue: *mut u16,
    }

    #[link(name = "X11")]
    unsafe extern "C" {
        fn XOpenDisplay(display_name: *const c_char) -> *mut Display;
        fn XDefaultRootWindow(display: *mut Display) -> Window;
        fn XCloseDisplay(display: *mut Display);
    }

    #[link(name = "Xrandr")]
    unsafe extern "C" {
        fn XRRGetScreenResourcesCurrent(
            display: *mut Display,
            window: Window,
        ) -> *mut XRRScreenResources;
        fn XRRFreeScreenResources(resources: *mut XRRScreenResources);
        fn XRRGetCrtcGammaSize(display: *mut Display, crtc: RRCrtc) -> c_int;
        fn XRRAllocGamma(size: c_int) -> *mut XRRCrtcGamma;
        fn XRRFreeGamma(gamma: *mut XRRCrtcGamma);
        fn XRRSetCrtcGamma(display: *mut Display, crtc: RRCrtc, gamma: *mut XRRCrtcGamma);
    }

    pub fn apply_filter(channel_scales: [f64; 3]) -> Result<(), String> {
        unsafe {
            let display = XOpenDisplay(std::ptr::null());
            if display.is_null() {
                let error = String::from("Cannot open standard X11 display context connection.");
                eprintln!("Error: {error}");
                return Err(error);
            }

            let root = XDefaultRootWindow(display);
            let resources = XRRGetScreenResourcesCurrent(display, root);
            if resources.is_null() {
                let error = String::from("Failed to obtain screen layout resources via X11 RandR.");
                eprintln!("Error: {error}");
                XCloseDisplay(display);
                return Err(error);
            }

            let ncrtc = (*resources).ncrtc;
            let crtcs = std::slice::from_raw_parts((*resources).crtcs, ncrtc as usize);

            for &crtc in crtcs {
                let gamma_size = XRRGetCrtcGammaSize(display, crtc);
                if gamma_size <= 0 {
                    continue;
                }

                let gamma = XRRAllocGamma(gamma_size);
                if gamma.is_null() {
                    continue;
                }

                let red_slice = std::slice::from_raw_parts_mut((*gamma).red, gamma_size as usize);
                let green_slice =
                    std::slice::from_raw_parts_mut((*gamma).green, gamma_size as usize);
                let blue_slice = std::slice::from_raw_parts_mut((*gamma).blue, gamma_size as usize);

                for i in 0..gamma_size as usize {
                    let val = (i as f64 / (gamma_size - 1) as f64) * 65535.0;
                    red_slice[i] = (val * channel_scales[0]).round() as u16;
                    green_slice[i] = (val * channel_scales[1]).round() as u16;
                    blue_slice[i] = (val * channel_scales[2]).round() as u16;
                }

                XRRSetCrtcGamma(display, crtc, gamma);
                XRRFreeGamma(gamma);
            }

            XRRFreeScreenResources(resources);
            XCloseDisplay(display);
            println!("System display filter applied successfully.");
            Ok(())
        }
    }
}
