#!/usr/bin/env python3

# START ### IMPORTS ###
import os
import sys
import time
import psutil
import json
import GPUtil
from pathlib import Path
from datetime import datetime
from rich.live import Live
from rich.table import Table
from rich.console import Console
from rich.panel import Panel
# FINISH ### IMPORTS ###

# START ### CONSOLE SETUP ###
console = Console()
# FINISH ### CONSOLE SETUP ###

# START ### SYSTEM MONITOR ###
class SystemMonitor:
    def __init__(self):
        self.start_time = time.time()
        self.last_net_io = psutil.net_io_counters()
        self.last_io_time = time.time()

    def get_uptime(self):
        """Get system uptime"""
        return time.time() - self.start_time

    def get_cpu_usage(self):
        """Get CPU usage"""
        return psutil.cpu_percent(interval=1)

    def get_memory_usage(self):
        """Get memory usage"""
        mem = psutil.virtual_memory()
        return {
            'total': mem.total / (1024**3),
            'used': mem.used / (1024**3),
            'percent': mem.percent
        }

    def get_gpu_stats(self):
        """Get GPU statistics"""
        try:
            gpus = GPUtil.getGPUs()
            if not gpus:
                return None
            
            gpu = gpus[0]  # Using first GPU
            return {
                'name': gpu.name,
                'load': gpu.load * 100,
                'memory': {
                    'total': gpu.memoryTotal,
                    'used': gpu.memoryUsed,
                    'free': gpu.memoryFree,
                    'percent': (gpu.memoryUsed / gpu.memoryTotal) * 100
                },
                'temperature': gpu.temperature
            }
        except:
            return None

    def get_network_stats(self):
        """Get network statistics"""
        current_net_io = psutil.net_io_counters()
        current_time = time.time()
        
        time_delta = current_time - self.last_io_time
        bytes_sent = (current_net_io.bytes_sent - self.last_net_io.bytes_sent) / time_delta
        bytes_recv = (current_net_io.bytes_recv - self.last_net_io.bytes_recv) / time_delta
        
        self.last_net_io = current_net_io
        self.last_io_time = current_time
        
        return {
            'sent': bytes_sent / (1024**2),  # MB/s
            'received': bytes_recv / (1024**2)  # MB/s
        }

    def get_disk_usage(self):
        """Get disk usage"""
        disk = psutil.disk_usage('/')
        return {
            'total': disk.total / (1024**3),
            'used': disk.used / (1024**3),
            'free': disk.free / (1024**3),
            'percent': disk.percent
        }
# FINISH ### SYSTEM MONITOR ###

# START ### DISPLAY MANAGER ###
def create_status_table(monitor):
    """Create status display table"""
    table = Table(title="System Monitor", border_style="cyan")
    
    # Add columns
    table.add_column("Metric", style="cyan")
    table.add_column("Value", style="green")
    
    # Uptime
    uptime = time.strftime('%H:%M:%S', time.gmtime(monitor.get_uptime()))
    table.add_row("Uptime", uptime)
    
    # CPU
    cpu = monitor.get_cpu_usage()
    table.add_row("CPU Usage", f"{cpu:.1f}%")
    
    # Memory
    mem = monitor.get_memory_usage()
    table.add_row("Memory Usage", 
                 f"{mem['used']:.1f}GB / {mem['total']:.1f}GB ({mem['percent']}%)")
    
    # GPU
    gpu = monitor.get_gpu_stats()
    if gpu:
        table.add_row("GPU Name", gpu['name'])
        table.add_row("GPU Load", f"{gpu['load']:.1f}%")
        table.add_row("GPU Memory", 
                     f"{gpu['memory']['used']:.1f}GB / {gpu['memory']['total']:.1f}GB "
                     f"({gpu['memory']['percent']:.1f}%)")
        table.add_row("GPU Temperature", f"{gpu['temperature']}Â°C")
    
    # Network
    net = monitor.get_network_stats()
    table.add_row("Network I/O", 
                 f"â†‘ {net['sent']:.2f} MB/s | â†“ {net['received']:.2f} MB/s")
    
    # Disk
    disk = monitor.get_disk_usage()
    table.add_row("Disk Usage",
                 f"{disk['used']:.1f}GB / {disk['total']:.1f}GB ({disk['percent']}%)")
    
    return table
# FINISH ### DISPLAY MANAGER ###

# START ### MAIN FUNCTION ###
def main():
    console.print(Panel.fit(
        "[cyan]SYSTEM MONITOR[/cyan]\n"
        "[yellow]Keeping an eye on your resources[/yellow]",
        border_style="cyan"
    ))
    
    monitor = SystemMonitor()
    
    try:
        with Live(console=console, refresh_per_second=2) as live:
            while True:
                live.update(create_status_table(monitor))
                time.sleep(0.5)
    except KeyboardInterrupt:
        console.print("\n[yellow]Monitor stopped by user[/yellow]")
# FINISH ### MAIN FUNCTION ###

# START ### SCRIPT RUNNER ###
if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        console.print(f"\n[red]Critical error: {str(e)}[/red]")
        sys.exit(1)
# FINISH ### SCRIPT RUNNER ###