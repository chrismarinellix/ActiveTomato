// Prevents additional console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri::{
    Manager,
    LogicalSize,
    LogicalPosition,
    tray::TrayIconBuilder,
    menu::{Menu, MenuItem},
};
use std::sync::atomic::{AtomicBool, Ordering};

static IS_WIDGET_MODE: AtomicBool = AtomicBool::new(false);

#[tauri::command]
fn toggle_widget_mode(window: tauri::WebviewWindow) {
    let is_widget = IS_WIDGET_MODE.load(Ordering::SeqCst);
    IS_WIDGET_MODE.store(!is_widget, Ordering::SeqCst);

    if !is_widget {
        // Switch to widget mode - compact floating orb
        let _ = window.set_size(LogicalSize::new(280.0, 360.0));
        let _ = window.set_decorations(false);
        let _ = window.set_always_on_top(true);
        let _ = window.set_skip_taskbar(true);

        // Position bottom-right with nice margin
        if let Ok(monitor) = window.current_monitor() {
            if let Some(monitor) = monitor {
                let size = monitor.size();
                let scale = monitor.scale_factor();
                let x = (size.width as f64 / scale) - 300.0;
                let y = (size.height as f64 / scale) - 400.0;
                let _ = window.set_position(LogicalPosition::new(x, y));
            }
        }

        // Inject widget CSS - ultra floating style
        let _ = window.eval(r#"
            document.body.classList.add('widget-mode');
            if (!document.getElementById('widget-style')) {
                const style = document.createElement('style');
                style.id = 'widget-style';
                style.textContent = `
                    body.widget-mode {
                        background: transparent !important;
                        -webkit-app-region: drag;
                    }
                    body.widget-mode .container {
                        padding: 0 !important;
                        background: transparent !important;
                    }
                    body.widget-mode #webgl-bg { display: none !important; }
                    body.widget-mode .eink-screen {
                        height: 100vh !important;
                        max-width: 100% !important;
                        border-radius: 32px !important;
                        background: rgba(245, 245, 240, 0.85) !important;
                        backdrop-filter: blur(30px) saturate(180%) !important;
                        -webkit-backdrop-filter: blur(30px) saturate(180%) !important;
                        box-shadow:
                            0 25px 80px rgba(0,0,0,0.35),
                            0 10px 30px rgba(0,0,0,0.2),
                            inset 0 1px 0 rgba(255,255,255,0.6),
                            0 0 0 1px rgba(255,255,255,0.3) !important;
                        border: none !important;
                        padding: 20px !important;
                    }
                    body.widget-mode .header,
                    body.widget-mode .activity-section,
                    body.widget-mode .toggle-panels,
                    body.widget-mode .series-selector { display: none !important; }
                    body.widget-mode .screen-content { overflow: visible !important; }
                    body.widget-mode .main-content {
                        padding: 10px !important;
                        justify-content: center !important;
                    }
                    body.widget-mode .timer-display {
                        margin: 10px 0 !important;
                    }
                    body.widget-mode .timer-digits {
                        font-size: 3rem !important;
                        font-weight: 600 !important;
                    }
                    body.widget-mode .timer-label {
                        font-size: 0.6rem !important;
                    }
                    body.widget-mode .mode-tabs {
                        margin-bottom: 12px !important;
                        transform: scale(0.9);
                    }
                    body.widget-mode .mode-tab {
                        padding: 6px 12px !important;
                        font-size: 0.55rem !important;
                    }
                    body.widget-mode .timer-progress {
                        max-width: 200px !important;
                        margin-top: 15px !important;
                    }
                    body.widget-mode .interval-indicator { display: none !important; }
                    body.widget-mode .controls {
                        margin: 12px 0 5px !important;
                        gap: 8px !important;
                    }
                    body.widget-mode .btn {
                        padding: 8px 18px !important;
                        font-size: 0.65rem !important;
                        -webkit-app-region: no-drag;
                        border-radius: 6px !important;
                    }
                    body.widget-mode .btn.primary {
                        box-shadow: 0 4px 15px rgba(0,0,0,0.2) !important;
                    }
                `;
                document.head.appendChild(style);
            }
        "#);
    } else {
        // Switch back to full mode
        let _ = window.set_size(LogicalSize::new(1000.0, 750.0));
        let _ = window.set_decorations(true);
        let _ = window.set_always_on_top(false);
        let _ = window.set_skip_taskbar(false);
        let _ = window.center();

        // Remove widget CSS
        let _ = window.eval(r#"
            document.body.classList.remove('widget-mode');
            const style = document.getElementById('widget-style');
            if (style) style.remove();
        "#);
    }
}

#[tauri::command]
fn set_always_on_top(window: tauri::WebviewWindow, on_top: bool) {
    let _ = window.set_always_on_top(on_top);
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![toggle_widget_mode, set_always_on_top])
        .setup(|app| {
            // Create tray menu
            let show = MenuItem::with_id(app, "show", "Show ActiveTomato", true, None::<&str>)?;
            let hide = MenuItem::with_id(app, "hide", "Hide", true, None::<&str>)?;
            let quit = MenuItem::with_id(app, "quit", "Quit", true, None::<&str>)?;
            let menu = Menu::with_items(app, &[&show, &hide, &quit])?;

            // Build tray icon
            TrayIconBuilder::new()
                .icon(app.default_window_icon().unwrap().clone())
                .menu(&menu)
                .show_menu_on_left_click(false)
                .on_menu_event(|app, event| {
                    match event.id.as_ref() {
                        "show" => {
                            if let Some(window) = app.get_webview_window("main") {
                                let _ = window.show();
                                let _ = window.set_focus();
                            }
                        }
                        "hide" => {
                            if let Some(window) = app.get_webview_window("main") {
                                let _ = window.hide();
                            }
                        }
                        "quit" => {
                            app.exit(0);
                        }
                        _ => {}
                    }
                })
                .on_tray_icon_event(|tray, event| {
                    if let tauri::tray::TrayIconEvent::Click { button: tauri::tray::MouseButton::Left, .. } = event {
                        let app = tray.app_handle();
                        if let Some(window) = app.get_webview_window("main") {
                            let _ = window.show();
                            let _ = window.set_focus();
                        }
                    }
                })
                .build(app)?;

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
