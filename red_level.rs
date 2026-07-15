use clap::Parser;

#[derive(Parser, Debug)]
#[command(
    name = "red_level",
    about = "System-level software dimming and blue/green blocking filters to prevent PWM flicker.",
    version = "1.0.0"
)]
struct Args {
    /// Brightness level in percentage (1 to 100)
    #[arg(short, long, default_value_t = 100)]
    brightness: u8,

    /// Block 100% of Blue and Green light (leaving only Red active)
    #[arg(short, long)]
    red_only: bool,

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

fn main() {
    let args = Args::parse();

    #[cfg(target_family = "unix")]
    {
        if args.start {
            unix_daemon::start_daemon(args.brightness, args.red_only);
            return;
        }
        if args.stop {
            unix_daemon::stop_daemon();
            return;
        }
    }

    #[cfg(not(target_family = "unix"))]
    if args.start || args.stop {
        eprintln!("Error: Background process management is currently available only on Unix-like operating systems (macOS/Linux).");
        std::process::exit(1);
    }

    let clamped_brightness = args.brightness.clamp(1, 100);
    let scale = if args.reset {
        1.0
    } else {
        clamped_brightness as f64 / 100.0
    };
    let red_only = if args.reset { false } else { args.red_only };

    if args.reset {
        println!("Resetting screen filter and restoring original gamma curves...");
    } else {
        println!(
            "Applying Filter -> Software Brightness: {}% | Red-Only mode: {}",
            clamped_brightness,
            if red_only { "ON" } else { "OFF" }
        );
    }

    #[cfg(target_os = "windows")]
    {
        windows_impl::apply_filter(scale, red_only);
    }

    #[cfg(target_os = "macos")]
    {
        macos_impl::apply_filter(scale, red_only);
    }

    #[cfg(target_os = "linux")]
    {
        linux_impl::apply_filter(scale, red_only);
    }

    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    {
        eprintln!(
            "Error: This application is currently only optimized for macOS, Windows, and Linux platforms."
        );
        std::process::exit(1);
    }

    // If running in foreground or daemon loop on non-Windows desktop platforms
    #[cfg(target_family = "unix")]
    {
        if !args.reset {
            if args.daemon {
                loop {
                    std::thread::park();
                }
            }

            println!("Filter active. Press Ctrl+C to restore the display.");
            
            // Catch termination signals to restore screen smoothly
            let _ = ctrlc::set_handler(move || {
                println!("\nRestoring screen defaults...");
                #[cfg(target_os = "macos")]
                macos_impl::apply_filter(1.0, false);
                #[cfg(target_os = "linux")]
                linux_impl::apply_filter(1.0, false);
                std::process::exit(0);
            });

            loop {
                std::thread::park();
            }
        }
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

    extern "C" {
        fn getuid() -> u32;
        fn kill(pid: i32, signal: i32) -> i32;
        fn setsid() -> i32;
    }

    fn pid_file() -> PathBuf {
        let uid = unsafe { getuid() };
        std::env::temp_dir().join(format!("red_level-{uid}.pid"))
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

    pub fn start_daemon(brightness: u8, red_only: bool) {
        if let Some(pid) = read_running_pid() {
            eprintln!("Error: red_level is already running with process ID {pid}.");
            std::process::exit(1);
        }

        let executable = match std::env::current_exe() {
            Ok(path) => path,
            Err(error) => {
                eprintln!("Error: Failed to locate red_level: {error}");
                std::process::exit(1);
            }
        };

        let mut command = Command::new(executable);
        command
            .arg("--daemon")
            .arg("--brightness")
            .arg(brightness.clamp(1, 100).to_string())
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null());
        if red_only {
            command.arg("--red-only");
        }

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
                eprintln!("Error: Failed to start red_level background daemon: {error}");
                std::process::exit(1);
            }
        };

        if let Err(error) = fs::write(pid_file(), child.id().to_string()) {
            unsafe {
                kill(child.id() as i32, SIGTERM);
            }
            eprintln!("Error: Failed to save the red_level process ID: {error}");
            std::process::exit(1);
        }

        println!("red_level daemon started successfully with process ID {}.", child.id());
    }

    pub fn stop_daemon() {
        let Some(pid) = read_running_pid() else {
            eprintln!("Error: red_level is not running in the background.");
            std::process::exit(1);
        };

        if unsafe { kill(pid, SIGTERM) } != 0 {
            eprintln!(
                "Error: Failed to stop red_level: {}",
                std::io::Error::last_os_error()
            );
            std::process::exit(1);
        }

        // Clean up display natively upon exit
        std::thread::sleep(std::time::Duration::from_millis(150));
        #[cfg(target_os = "macos")]
        super::macos_impl::apply_filter(1.0, false);
        #[cfg(target_os = "linux")]
        super::linux_impl::apply_filter(1.0, false);

        if let Err(error) = fs::remove_file(pid_file()) {
            eprintln!("Warning: Failed to remove the red_level PID lockfile: {error}");
        }
        println!("red_level daemon stopped; the display has been restored.");
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

    pub fn apply_filter(brightness_scale: f64, red_only: bool) {
        let hdc = unsafe { GetDC(None) };
        if hdc.is_invalid() {
            eprintln!("Error: Failed to acquire display device context (HDC).");
            return;
        }

        let mut ramp = [0u16; 768];

        for i in 0..256 {
            let val = (i as f64 / 255.0) * 65535.0;

            ramp[i] = (val * brightness_scale).round() as u16;

            if red_only {
                ramp[i + 256] = 0;
                ramp[i + 512] = 0;
            } else {
                ramp[i + 256] = (val * brightness_scale).round() as u16;
                ramp[i + 512] = (val * brightness_scale).round() as u16;
            }
        }

        let result = unsafe { SetDeviceGammaRamp(hdc, ramp.as_ptr() as *const c_void) };
        if result.as_bool() {
            println!("System display filter applied successfully.");
        } else {
            eprintln!(
                "Error: SetDeviceGammaRamp failed. Native HDR or administrative limits may apply."
            );
        }
    }
}

// ==========================================
// macOS COREGRAPHICS FFI ENGINE
// ==========================================
#[cfg(target_os = "macos")]
mod macos_impl {
    type CGDirectDisplayID = u32;
    type CGError = i32;

    #[link(name = "CoreGraphics", kind = "framework")]
    extern "C" {
        fn CGMainDisplayID() -> CGDirectDisplayID;
        fn CGSetDisplayTransferByTable(
            display: CGDirectDisplayID,
            table_size: u32,
            red_table: *const f32,
            green_table: *const f32,
            blue_table: *const f32,
        ) -> CGError;
    }

    pub fn apply_filter(brightness_scale: f64, red_only: bool) {
        let display_id = unsafe { CGMainDisplayID() };
        const TABLE_SIZE: usize = 256;

        let mut red_table = [0.0f32; TABLE_SIZE];
        let mut green_table = [0.0f32; TABLE_SIZE];
        let mut blue_table = [0.0f32; TABLE_SIZE];

        for i in 0..TABLE_SIZE {
            let val = (i as f32 / (TABLE_SIZE - 1) as f32) * brightness_scale as f32;

            red_table[i] = val;
            if red_only {
                green_table[i] = 0.0;
                blue_table[i] = 0.0;
            } else {
                green_table[i] = val;
                blue_table[i] = val;
            }
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
        } else {
            eprintln!(
                "Error: CGSetDisplayTransferByTable failed with code {}.",
                result
            );
        }
    }
}

// ==========================================
// LINUX X11 / XRANDR FFI ENGINE
// ==========================================
#[cfg(target_os = "linux")]
mod linux_impl {
    use std::os::raw::{c_char, c_int, c_void, c_ulong};

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
    extern "C" {
        fn XOpenDisplay(display_name: *const c_char) -> *mut Display;
        fn XDefaultRootWindow(display: *mut Display) -> Window;
        fn XCloseDisplay(display: *mut Display);
    }

    #[link(name = "Xrandr")]
    extern "C" {
        fn XRRGetScreenResourcesCurrent(display: *mut Display, window: Window) -> *mut XRRScreenResources;
        fn XRRFreeScreenResources(resources: *mut XRRScreenResources);
        fn XRRGetCrtcGammaSize(display: *mut Display, crtc: RRCrtc) -> c_int;
        fn XRRAllocGamma(size: c_int) -> *mut XRRCrtcGamma;
        fn XRRFreeGamma(gamma: *mut XRRCrtcGamma);
        fn XRRSetCrtcGamma(display: *mut Display, crtc: RRCrtc, gamma: *mut XRRCrtcGamma);
    }

    pub fn apply_filter(brightness_scale: f64, red_only: bool) {
        unsafe {
            let display = XOpenDisplay(std::ptr::null());
            if display.is_null() {
                eprintln!("Error: Cannot open standard X11 display context connection.");
                return;
            }

            let root = XDefaultRootWindow(display);
            let resources = XRRGetScreenResourcesCurrent(display, root);
            if resources.is_null() {
                eprintln!("Error: Failed to obtain screen layout resources via X11 RandR.");
                XCloseDisplay(display);
                return;
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
                let green_slice = std::slice::from_raw_parts_mut((*gamma).green, gamma_size as usize);
                let blue_slice = std::slice::from_raw_parts_mut((*gamma).blue, gamma_size as usize);

                for i in 0..gamma_size as usize {
                    let val = (i as f64 / (gamma_size - 1) as f64) * 65535.0;
                    red_slice[i] = (val * brightness_scale).round() as u16;

                    if red_only {
                        green_slice[i] = 0;
                        blue_slice[i] = 0;
                    } else {
                        green_slice[i] = (val * brightness_scale).round() as u16;
                        blue_slice[i] = (val * brightness_scale).round() as u16;
                    }
                }

                XRRSetCrtcGamma(display, crtc, gamma);
                XRRFreeGamma(gamma);
            }

            XRRFreeScreenResources(resources);
            XCloseDisplay(display);
            println!("System display filter applied successfully.");
        }
    }
}
