#!/usr/bin/env python3
"""
Touchpad Toggle System Tray Applet - X-Seti Oct 12 2024
For KDE Plasma 6 on Wayland
Version: 3.0 - Uses sysfs inhibit method that actually works!
"""

import sys
import subprocess
import os
from pathlib import Path
from PyQt6.QtWidgets import QApplication, QSystemTrayIcon, QMenu
from PyQt6.QtCore import QTimer
from PyQt6.QtGui import QIcon, QAction

# Hardcoded based on diagnostic - your touchpad is event10
EVENT_DEVICE = "event10"
INHIBIT_PATH = f"/sys/class/input/{EVENT_DEVICE}/device/inhibited"

class TouchpadTrayIcon(QSystemTrayIcon):
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Verify inhibit path exists
        if not Path(INHIBIT_PATH).exists():
            print(f"Warning: {INHIBIT_PATH} not found!")
            subprocess.run(['notify-send', 'Touchpad Toggle', 
                          'Error: Could not find touchpad device'], check=False)
        
        # Create menu
        menu = QMenu()
        self.toggle_action = QAction("Toggle Touchpad", self)
        self.toggle_action.triggered.connect(self.toggle_touchpad)
        
        self.status_action = QAction("Status: Checking...", self)
        self.status_action.setEnabled(False)
        
        quit_action = QAction("Quit", self)
        quit_action.triggered.connect(QApplication.quit)
        
        menu.addAction(self.status_action)
        menu.addSeparator()
        menu.addAction(self.toggle_action)
        menu.addAction(quit_action)
        
        self.setContextMenu(menu)
        
        # Connect click to toggle
        self.activated.connect(self.on_activated)
        
        # Update status
        self.update_status()
        
        # Check status every 2 seconds
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_status)
        self.timer.start(2000)
        
        self.show()
    
    def on_activated(self, reason):
        if reason == QSystemTrayIcon.ActivationReason.Trigger:  # Left click
            self.toggle_touchpad()
    
    def is_enabled(self):
        """Check if touchpad is enabled via sysfs inhibit"""
        try:
            with open(INHIBIT_PATH, 'r') as f:
                # 0 = enabled, 1 = disabled
                state = f.read().strip()
                return state == '0'
        except:
            return True  # Assume enabled if can't read
    
    def toggle_touchpad(self):
        """Toggle touchpad on/off using sysfs inhibit"""
        enabled = self.is_enabled()
        new_state = '1' if enabled else '0'  # 1 = disable, 0 = enable
        
        try:
            # This requires root, so use pkexec
            result = subprocess.run(
                ['pkexec', 'bash', '-c', f'echo {new_state} > {INHIBIT_PATH}'],
                capture_output=True,
                timeout=30  # Give user time to enter password
            )
            
            if result.returncode == 0:
                # Success!
                status = "Enabled" if new_state == '0' else "Disabled"
                subprocess.run(['notify-send', 'Touchpad', status], check=False)
                
                # Force immediate update
                self.update_status()
            else:
                # User probably cancelled password dialog
                subprocess.run(['notify-send', 'Touchpad', 
                              'Toggle cancelled (no password)'], check=False)
        except subprocess.TimeoutExpired:
            subprocess.run(['notify-send', 'Touchpad', 
                          'Toggle timed out'], check=False)
        except Exception as e:
            subprocess.run(['notify-send', 'Touchpad', 
                          f'Toggle failed: {str(e)}'], check=False)
    
    def update_status(self):
        """Update icon and status text"""
        enabled = self.is_enabled()
        
        # Update status text
        status = "Enabled ✓" if enabled else "Disabled ✗"
        self.status_action.setText(f"Touchpad: {status}")
        
        # Update tooltip
        self.setToolTip(f"Touchpad {status}")
        
        # Set icon (using system theme icons)
        icon_name = "input-touchpad" if enabled else "input-touchpad-off"
        self.setIcon(QIcon.fromTheme(icon_name, QIcon.fromTheme("input-mouse")))

def main():
    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)
    
    tray = TouchpadTrayIcon()
    
    sys.exit(app.exec())

if __name__ == '__main__':
    main()
