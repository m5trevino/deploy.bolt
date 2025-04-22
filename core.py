import pyperclip
import time
import threading
from collections import deque
import logging

# START ### LOGGING SETUP ###
# Basic logging config. We'll want more sophisticated shit later, maybe file logging.
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
# FINISH ### LOGGING SETUP ###

# START ### CLIPBOARD MANAGER CLASS ###
class ClipboardManager:
    """
    Manages clipboard monitoring, history storage, and related operations.
    The engine room for the multiclip hustle.
    """
    # START ### CLASS INITIALIZATION ###
    def __init__(self, max_history=25):
        """
        Initializes the ClipboardManager.

        Args:
            max_history (int): The maximum number of clips to keep in history.
                               Like settin' a limit on how much inventory you hold.
        """
        logging.info(f"Initializing ClipboardManager with max history: {max_history}")
        # Using deque for efficient additions and automatic trimming
        self.history = deque(maxlen=max_history)
        self.pinned_clips = {} # We'll use this later for pinned items {hotkey: content}
        self.last_copied_content = self._get_current_clipboard() # Get initial state
        self._monitoring_active = False
        self._monitor_thread = None
        self._stop_event = threading.Event() # Use an Event for cleaner thread stopping

        # Initialize with current clipboard content if it's not empty
        if self.last_copied_content:
            logging.info("Adding initial clipboard content to history.")
            # Avoid adding initial content if it's just whitespace
            if self.last_copied_content.strip():
                self._add_to_history(self.last_copied_content)
            else:
                logging.info("Initial clipboard content is whitespace, skipping add.")
        else:
            logging.info("Initial clipboard is empty or inaccessible.")

    # FINISH ### CLASS INITIALIZATION ###

    # START ### CLIPBOARD ACCESS UTILITY ###
    def _get_current_clipboard(self):
        """
        Safely gets the current clipboard content (text only for now).
        Handles potential errors if the clipboard is weird. Like checkin' if the product is legit.
        """
        try:
            # TODO: Add support for other types later (images, files?)
            content = pyperclip.paste()
            # Check if content is actually text data, not some weird object handle
            if isinstance(content, str):
                return content
            else:
                # Handle cases where pyperclip might return non-string (less common now, but safe)
                logging.warning(f"Clipboard content was not a string: {type(content)}. Attempting conversion.")
                try:
                    # Try converting common types just in case
                    return str(content)
                except Exception as conversion_e:
                     logging.error(f"Could not convert clipboard content to string: {conversion_e}", exc_info=True)
                     return None

        except pyperclip.PyperclipException as e:
            # Known pyperclip issues (e.g., clipboard unavailable, non-text formats it doesn't handle)
            logging.error(f"PyperclipException accessing clipboard: {e}")
            return None
        except Exception as e:
            # Catch unexpected errors during paste
            logging.error(f"Unexpected error getting clipboard content: {e}", exc_info=True)
            return None

    # FINISH ### CLIPBOARD ACCESS UTILITY ###

    # START ### HISTORY MANAGEMENT ###
    def _add_to_history(self, content):
        """
        Adds new content to the history deque. #1 is the latest.
        Prepends the new item (timestamp, content). Timestamp helps keep order true.
        """
        # Basic check to prevent adding empty or only whitespace strings
        if not content or content.isspace():
            logging.debug("Skipping empty or whitespace-only clip.")
            return False

        timestamp = time.time()
        new_entry = (timestamp, content)

        # Avoid adding duplicates: Check the *most recent* item in history if history is not empty
        if self.history and self.history[0][1] == content:
             logging.debug(f"Skipping duplicate clip: {content[:30]}...")
             return False # Indicate not added

        logging.info(f"Adding new clip to history: {content[:30]}...")
        self.history.appendleft(new_entry) # appendleft makes it the new #1
        # TODO: Add persistence logic here later (e.g., save history to file/db)
        return True # Indicate added

    def get_history(self):
        """
        Returns the current history as a list of (timestamp, content) tuples.
        Latest item first. Ready for display.
        """
        # Return a copy to prevent external modification
        return list(self.history)

    def clear_history(self):
        """ Clears the clipboard history. Like cleaning out the stash spot. """
        logging.info("Clearing clipboard history.")
        self.history.clear()
        # TODO: Add persistence logic here later (e.g., clear saved history file/db)
        # Maybe keep pinned clips? TBD. For now, clears everything non-pinned.

    # FINISH ### HISTORY MANAGEMENT ###

    # START ### MONITORING LOGIC ###
    def _monitor_clipboard(self):
        """
        The core loop that runs in a separate thread to watch the clipboard.
        This is the lookout, constantly checkin' the corners (clipboard).
        """
        logging.info("Clipboard monitoring thread started.")
        consecutive_error_count = 0
        MAX_CONSECUTIVE_ERRORS = 5 # Stop spamming logs if clipboard is consistently broken

        while not self._stop_event.is_set():
            try:
                current_content = self._get_current_clipboard()

                # Check if content is valid (not None) and different from the last *recorded* copy
                if current_content is not None and current_content != self.last_copied_content:
                    logging.debug(f"Detected potential new clip: {current_content[:30]}...")
                    added = self._add_to_history(current_content)
                    if added:
                        # Update last_copied_content *only* if it was successfully added
                        self.last_copied_content = current_content
                        # TODO: Signal the UI or other parts that history updated
                        logging.info("Clipboard history updated.")
                        # Reset error count on success
                        consecutive_error_count = 0

                # Reset error count if clipboard read was successful (even if content was same/empty)
                if current_content is not None:
                     consecutive_error_count = 0

                # Wait a bit before checking again, don't hog the CPU
                # Use wait on the event for faster shutdown
                self._stop_event.wait(0.5) # Check every 0.5 seconds

            except Exception as e:
                consecutive_error_count += 1
                logging.error(f"Error during clipboard monitoring loop (Count: {consecutive_error_count}): {e}", exc_info=True)
                if consecutive_error_count >= MAX_CONSECUTIVE_ERRORS:
                     logging.critical("Too many consecutive errors reading clipboard. Pausing monitoring for 60s.")
                     self._stop_event.wait(60) # Pause for a minute before retrying
                     consecutive_error_count = 0 # Reset count after long pause
                else:
                     # Avoid spamming logs if error persists rapidly
                     time.sleep(5) # Short sleep for transient errors

        logging.info("Clipboard monitoring thread stopped.")


    def start_monitoring(self):
        """ Starts the clipboard monitoring thread if not already running. """
        if not self._monitoring_active:
            # Check if thread exists and is dead before creating new one
            if self._monitor_thread and not self._monitor_thread.is_alive():
                 logging.warning("Previous monitor thread found dead. Cleaning up.")
                 self._monitor_thread = None # Clear the dead thread reference

            if not self._monitor_thread: # Only create thread if it doesn't exist or was cleared
                logging.info("Starting clipboard monitor...")
                self._stop_event.clear() # Ensure the stop flag is reset
                self._monitor_thread = threading.Thread(target=self._monitor_clipboard, daemon=True)
                # Daemon=True means thread won't block program exit
                self._monitor_thread.start()
                self._monitoring_active = True
            else:
                 # This case should ideally not be hit if logic is correct, but safety first
                 logging.warning("Monitor thread exists but start was called again? State confusion.")
        else:
            logging.warning("Monitoring is already active.")

    def stop_monitoring(self):
        """ Stops the clipboard monitoring thread gracefully. """
        if self._monitoring_active:
            logging.info("Stopping clipboard monitor...")
            self._stop_event.set() # Signal the thread to stop
            if self._monitor_thread and self._monitor_thread.is_alive():
                 self._monitor_thread.join(timeout=2) # Wait for thread to finish
                 if self._monitor_thread.is_alive():
                      logging.warning("Monitoring thread did not stop gracefully after 2 seconds.")
                 else:
                      logging.info("Monitoring thread joined successfully.")
            else:
                 logging.info("Monitor thread was not running or already finished.")

            self._monitoring_active = False
            self._monitor_thread = None # Clean up thread reference
        else:
            logging.warning("Monitoring is not active, cannot stop.")

    # FINISH ### MONITORING LOGIC ###

    # START ### PINNING FUNCTIONALITY (PLACEHOLDER) ###
    # TODO: Implement pinning logic
    def pin_clip(self, index_or_content):
        logging.warning("Pinning functionality not yet implemented.")
        pass

    def unpin_clip(self, hotkey_or_content):
        logging.warning("Unpinning functionality not yet implemented.")
        pass

    def get_pinned_clips(self):
        logging.warning("Pinned clips retrieval not yet implemented.")
        return self.pinned_clips
    # FINISH ### PINNING FUNCTIONALITY (PLACEHOLDER) ###

    # START ### SEQUENTIAL PASTE (PLACEHOLDER) ###
    # TODO: Implement sequential paste logic
    sequential_mode_active = False
    sequential_paste_index = 0

    def toggle_sequential_paste(self):
        logging.warning("Sequential paste toggle not yet implemented.")
        pass

    def get_next_sequential_clip(self):
        logging.warning("Sequential paste logic not yet implemented.")
        return None
    # FINISH ### SEQUENTIAL PASTE (PLACEHOLDER) ###

# FINISH ### CLIPBOARD MANAGER CLASS ###

# START ### SCRIPT RUNNER (FOR TESTING) ###
if __name__ == '__main__':
    # This block runs only when the script is executed directly
    # Useful for testing the core logic without the full app/UI.
    print("Running ClipboardManager test...")
    # Ensure we handle potential path issues if run from different directories
    # If using file logging later, configure path carefully
    manager = ClipboardManager(max_history=10)
    manager.start_monitoring()

    print("Clipboard monitor started. Copy text to see history updates.")
    print("Press Ctrl+C to stop.")

    try:
        while True:
            # Keep the main thread alive to let the monitor run
            # Print history periodically for testing - less spammy than every loop
            print("\n----- Current History (Latest First) -----")
            history = manager.get_history()
            if not history:
                print("-- Empty --")
            else:
                # Display in the numbered format we want (#1 = latest)
                for i, (ts, content) in enumerate(history, 1):
                    # Format timestamp nicely? Maybe later. Use ISO format for clarity?
                    # timestamp_str = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(ts))
                    print(f"#{i}: {content[:60].replace(chr(10), ' ')}...") # Show first 60 chars, replace newlines
            print("-------------------------------------------")
            # Sleep longer in the main thread for testing, monitor thread runs independently
            time.sleep(10)
    except KeyboardInterrupt:
        print("\nCtrl+C detected. Stopping test...")
    except Exception as main_e:
        print(f"\nUnexpected error in main loop: {main_e}")
    finally:
        print("Shutting down clipboard manager...")
        manager.stop_monitoring()
        print("Test finished.")
# FINISH ### SCRIPT RUNNER (FOR TESTING) ###
