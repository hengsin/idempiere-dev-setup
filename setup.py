import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib, Pango, Gdk # Gdk needed for CssProvider

import subprocess
import shlex
import sys
import threading
import os # For checking script existence and permissions
import signal # For sending signals to the process
import time # For small delays

class SetupScriptGTKUI:
    def __init__(self):
        # --- Default values from setup.sh (base defaults, some are PostgreSQL specific) ---
        self.defaults = {
            "db_type": "postgresql", 
            "idempiere_host": "0.0.0.0",
            "idempiere_port": "8080",
            "idempiere_ssl_port": "8443",
            "idempiere_source_folder": "idempiere",
            "source_url": "https://github.com/idempiere/idempiere.git",
            "clone_branch_enable": False,
            "branch_name": "",
            "eclipse_folder": "eclipse",
            "load_idempiere_env": False,
            "setup_ws": True,
            "setup_db": True,
            "install_copilot": False,
            "migrate_existing_database": True
        }
        self.postgresql_defaults = {
            "docker_postgres_create": False,
            "docker_postgres_name": "postgres",
            "oracle_docker_container": "",
            "oracle_docker_home": "",
            "db_name": "idempiere",
            "db_host": "localhost",
            "db_port": "5432",
            "db_user": "adempiere",
            "db_pass": "adempiere",
            "db_system_pass": "postgres"
        }
        self.oracle_defaults = {
            "docker_postgres_create": False,
            "docker_postgres_name": "",
            "oracle_docker_container": "",
            "oracle_docker_home": "/opt/oracle", 
            "db_name": "freepdb1",
            "db_host": "localhost",
            "db_port": "1521",
            "db_user": "idempiere",
            "db_pass": "idempiere",
            "db_system_pass": "oracle"
        }

        # --- GTK Widgets ---
        self.widgets = {} # For main window widgets
        self.output_window = None 
        self.output_textview_popup = None
        self.output_window_close_button = None # Reference to the close button in popup
        self.output_window_stop_button = None  # Reference to the stop button in popup

        # --- State Variables ---
        self.current_command_list_for_execution = []
        self.current_process = None 
        self.process_stopped_by_user = False 

        # --- Main Window ---
        self.window = Gtk.Window(title="iDempiere Development Setup Script Configurator")
        self.window.set_border_width(10)
        self.window.set_default_size(750, 650)
        self.window.connect("destroy", self._on_main_window_destroy) 

        main_scrolled_window = Gtk.ScrolledWindow()
        main_scrolled_window.set_hexpand(True)
        main_scrolled_window.set_vexpand(True)
        self.window.add(main_scrolled_window)

        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        main_vbox.set_border_width(5)
        main_scrolled_window.add(main_vbox)

        self.db_type = self.defaults.get("db_type")
        self._create_section(main_vbox, "Docker Postgres Configuration", [
            ("Create and run Docker Postgres container (--docker-postgres-create)", "docker_postgres_create", "check"),
            ("Docker Postgres Container Name (--docker-postgres-name)", "docker_postgres_name", "entry"),
        ])
        self._create_section(main_vbox, "Database Configuration", [
            ("Database Type", "db_type", "combo", ["postgresql", "oracle"], self._on_db_type_changed),
            ("Database Name (--db-name)", "db_name", "entry"),
            ("Database Host (--db-host)", "db_host", "entry"),
            ("Database Port (--db-port)", "db_port", "entry"),
            ("Database User (--db-user)", "db_user", "entry"),
            ("Database Password (--db-pass)", "db_pass", "entry_password"),
            ("DB System Admin Password (--db-admin-pass)", "db_system_pass", "entry_password"),
            ("Oracle Docker Container (--oracle-docker-container)", "oracle_docker_container", "entry"),
            ("Oracle Docker Home (--oracle-docker-home)", "oracle_docker_home", "entry"),
        ])
        self._create_section(main_vbox, "iDempiere Server Configuration", [
            ("HTTP Host (--http-host)", "idempiere_host", "entry"),
            ("HTTP Port (--http-port)", "idempiere_port", "entry"),
            ("HTTPS/SSL Port (--https-port)", "idempiere_ssl_port", "entry"),
        ])
        self._create_section(main_vbox, "Source Code & Environment", [
            ("iDempiere Source Folder (--source)", "idempiere_source_folder", "entry"),
            ("Git Repository URL (--repository-url)", "source_url", "entry"),
            ("Checkout a specific branch", "clone_branch_enable", "check_command", self._toggle_branch_name_entry),
            ("Branch Name (--branch)", "branch_name", "entry"), 
            ("Eclipse IDE Folder (--eclipse)", "eclipse_folder", "entry"),
        ])
        self._create_section(main_vbox, "Setup Options", [
            ("Load environment from idempiereEnv.properties (--load-idempiere-env)", "load_idempiere_env", "check"),
            ("Setup Eclipse Workspace (uncheck for --skip-setup-ws)", "setup_ws", "check"),
            ("Setup Database & Jetty (uncheck for --skip-setup-db)", "setup_db", "check"),
            ("Install GitHub Copilot plugin (--install-copilot)", "install_copilot", "check"),
            ("Run migration scripts (uncheck for --skip-migration-script)", "migrate_existing_database", "check"),
        ])

        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10, margin_top=10, margin_bottom=5, halign=Gtk.Align.CENTER)
        main_vbox.pack_start(button_box, False, False, 0) 

        self.widgets["generate_button"] = Gtk.Button(label="Generate Command")
        self.widgets["generate_button"].connect("clicked", self.generate_command_and_display)
        button_box.pack_start(self.widgets["generate_button"], False, True, 0)
        self.widgets["run_button"] = Gtk.Button(label="Run Command", sensitive=False)
        self.widgets["run_button"].connect("clicked", self.run_command)
        button_box.pack_start(self.widgets["run_button"], False, True, 0)
        self.widgets["reset_button"] = Gtk.Button(label="Reset Defaults")
        self.widgets["reset_button"].connect("clicked", self.reset_defaults)
        button_box.pack_start(self.widgets["reset_button"], False, True, 0)

        cmd_frame = Gtk.Frame(label="Generated Command", margin_top=5)
        main_vbox.pack_start(cmd_frame, True, True, 0) 
        cmd_scrolled_win = Gtk.ScrolledWindow()
        cmd_scrolled_win.set_min_content_height(80) 
        cmd_scrolled_win.set_shadow_type(Gtk.ShadowType.IN)
        cmd_scrolled_win.set_hexpand(True) 
        cmd_scrolled_win.set_vexpand(True) 
        cmd_frame.add(cmd_scrolled_win)
        self.widgets["generated_command_text"] = Gtk.TextView(editable=False, cursor_visible=False, wrap_mode=Gtk.WrapMode.WORD_CHAR)
        cmd_scrolled_win.add(self.widgets["generated_command_text"])
        
        self.reset_defaults(None, initial_setup=True) 
        self._toggle_branch_name_entry() 
        self.window.show_all()

    def _on_main_window_destroy(self, widget):
        if self.current_process and self.current_process.poll() is None: 
            self._terminate_process_forcefully() # Try to kill the process
        if self.output_window:
            self.output_window.destroy() 
        Gtk.main_quit()

    def _terminate_process_forcefully(self):
        """Attempts to terminate and then kill the current process."""
        if not self.current_process or self.current_process.poll() is not None:
            return

        pid = self.current_process.pid
        pgid = 0
        if os.name != "nt":
            try:
                pgid = os.getpgid(pid)
            except ProcessLookupError:
                pgid = 0 # Process might have already exited

        GLib.idle_add(self._append_to_popup_textview, f"\n--- Terminating process (PID: {pid}, PGID: {pgid if pgid else 'N/A'})... ---\n")
        
        try:
            if os.name != "nt" and pgid > 0: # On Unix, try to kill the process group
                os.killpg(pgid, signal.SIGTERM)
            else: # On Windows or if pgid couldn't be obtained
                self.current_process.terminate()
            
            # Wait for termination
            self.current_process.wait(timeout=2) # Increased timeout slightly
        except ProcessLookupError: # Process already exited
             GLib.idle_add(self._append_to_popup_textview, "--- Process already exited before termination attempt. ---\n")
        except subprocess.TimeoutExpired:
            GLib.idle_add(self._append_to_popup_textview, "--- Process did not terminate gracefully, attempting to kill... ---\n")
            try:
                if os.name != "nt" and pgid > 0:
                    os.killpg(pgid, signal.SIGKILL)
                else:
                    self.current_process.kill()
                self.current_process.wait(timeout=1) # Wait for kill
            except Exception as e:
                GLib.idle_add(self._append_to_popup_textview, f"--- Error during kill: {e} ---\n")
        except Exception as e: # Other errors during terminate/kill
            GLib.idle_add(self._append_to_popup_textview, f"--- Error during termination: {e} ---\n")
        finally:
            self.current_process = None # Clear process reference
            if self.output_window_close_button: self.output_window_close_button.set_sensitive(True)

    def _create_output_window(self):
        if self.output_window and self.output_window.get_visible():
            self.output_window.present()
            return
        
        if not self.output_window: 
            self.output_window = Gtk.Window(title="Execution Output / Status")
            self.output_window.set_default_size(650, 450)
            self.output_window.set_resizable(True)
            self.output_window.set_transient_for(self.window)
            self.output_window.set_modal(False)
            self.output_window.set_destroy_with_parent(False) 
            self.output_window.connect("delete-event", self._on_output_window_closed_event)

            vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
            vbox.set_border_width(5)
            self.output_window.add(vbox)

            scrolled_win = Gtk.ScrolledWindow(shadow_type=Gtk.ShadowType.IN)
            scrolled_win.set_hexpand(True)
            scrolled_win.set_vexpand(True)
            vbox.pack_start(scrolled_win, True, True, 0)

            self.output_textview_popup = Gtk.TextView(editable=False, cursor_visible=False, wrap_mode=Gtk.WrapMode.WORD_CHAR)
            css_provider = Gtk.CssProvider()
            css_provider.load_from_data(b"textview { font-family: Monospace; font-size: 10pt; }")
            self.output_textview_popup.get_style_context().add_provider(
                css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
            )
            scrolled_win.add(self.output_textview_popup)
            
            button_box_popup = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6, halign=Gtk.Align.END)
            vbox.pack_start(button_box_popup, False, False, 5)

            self.output_window_stop_button = Gtk.Button(label="Stop Process")
            self.output_window_stop_button.connect("clicked", self._on_stop_process_clicked)
            self.output_window_stop_button.set_sensitive(False) 
            button_box_popup.pack_start(self.output_window_stop_button, False, False, 0)

            self.output_window_close_button = Gtk.Button(label="Close")
            self.output_window_close_button.connect("clicked", lambda w: self.output_window.hide() if self.output_window else None)
            button_box_popup.pack_start(self.output_window_close_button, False, False, 0)

        self.output_window.show_all()
        self.output_window.present()

    def _on_output_window_closed_event(self, window, event):
        if self.output_window:
            self.output_window.hide() 
        return True 

    def _on_stop_process_clicked(self, widget):
        if self.current_process and self.current_process.poll() is None: 
            self.process_stopped_by_user = True # Set flag first
            self._terminate_process_forcefully()
        # UI updates for buttons will be handled by _update_ui_post_execution via check_completion_gtk
        # or immediately if process was already stopped.
        if self.output_window_stop_button:
             self.output_window_stop_button.set_sensitive(False) # Disable stop button immediately

    def _create_section(self, parent_vbox, title, fields_config):
        frame = Gtk.Frame(label=title, margin_bottom=5)
        parent_vbox.pack_start(frame, False, False, 0) 
        grid = Gtk.Grid(column_spacing=10, row_spacing=5, margin=10)
        frame.add(grid)
        row_in_grid = 0
        for field_data in fields_config:
            label_text, widget_key, widget_type = field_data[0], field_data[1], field_data[2]
            args = field_data[3:] 
            label = Gtk.Label(label=label_text + ":", xalign=0)
            grid.attach(label, 0, row_in_grid, 1, 1)
            widget = None
            if widget_type == "check":
                widget = Gtk.CheckButton(active=self.defaults.get(widget_key, False))
            elif widget_type == "check_command":
                callback = args[0] if args else None
                widget = Gtk.CheckButton(active=self.defaults.get(widget_key, False))
                if callback: widget.connect("toggled", callback)
            elif widget_type == "entry_password":
                if widget_key in self.defaults:
                    widget = Gtk.Entry(visibility=False, text=str(self.defaults.get(widget_key, "")))
                elif self.db_type == 'postgresql':
                    widget = Gtk.Entry(visibility=False, text=str(self.postgresql_defaults.get(widget_key, "")))
                else:
                    widget = Gtk.Entry(visibility=False, text=str(self.oracle_defaults.get(widget_key, "")))
            elif widget_type == "combo":
                options = args[0] if args else []
                callback = args[1] if len(args) > 1 else None
                widget = Gtk.ComboBoxText()
                for i, option_text in enumerate(options): widget.append_text(option_text)
                default_combo_val = str(self.defaults.get(widget_key, ""))
                if default_combo_val in options: widget.set_active(options.index(default_combo_val))
                elif options: widget.set_active(0)
                if callback: widget.connect("changed", callback)
            else: # "entry"
                if widget_key in self.defaults:
                    widget = Gtk.Entry(text=str(self.defaults.get(widget_key, "")))
                elif self.db_type == 'postgresql':
                    widget = Gtk.Entry(text=str(self.postgresql_defaults.get(widget_key, "")))
                else:
                    widget = Gtk.Entry(text=str(self.oracle_defaults.get(widget_key, "")))
            if widget:
                widget.set_hexpand(True)
                grid.attach(widget, 1, row_in_grid, 1, 1)
                self.widgets[widget_key] = widget
            row_in_grid += 1

    def _get_widget_value(self, widget_key):
        widget = self.widgets.get(widget_key)
        if isinstance(widget, Gtk.CheckButton): return widget.get_active()
        elif isinstance(widget, Gtk.Entry): return widget.get_text()
        elif isinstance(widget, Gtk.ComboBoxText): return widget.get_active_text()
        return None

    def _set_widget_value(self, widget_key, value):
        widget = self.widgets.get(widget_key)
        if isinstance(widget, Gtk.CheckButton): widget.set_active(bool(value))
        elif isinstance(widget, Gtk.Entry): widget.set_text(str(value))
        elif isinstance(widget, Gtk.ComboBoxText):
            model = widget.get_model()
            for i, row in enumerate(model):
                if row[0] == str(value): 
                    widget.set_active(i)
                    return
            if len(model) > 0: widget.set_active(0)

    def _on_db_type_changed(self, widget):
        self.db_type = self._get_widget_value("db_type")
        pg_docker_create_checkbox = self.widgets.get("docker_postgres_create")
        pg_docker_name_entry = self.widgets.get("docker_postgres_name")
        oracle_container_entry = self.widgets.get("oracle_docker_container")
        oracle_home_entry = self.widgets.get("oracle_docker_home")

        if self.db_type == "postgresql":
            self._set_widget_value("db_port", self.postgresql_defaults.get("db_port"))
            self._set_widget_value("db_name", self.postgresql_defaults.get("db_name"))
            self._set_widget_value("db_user", self.postgresql_defaults.get("db_user"))
            self._set_widget_value("db_pass", self.postgresql_defaults.get("db_pass"))
            self._set_widget_value("db_system_pass", self.postgresql_defaults.get("db_system_pass"))
            if pg_docker_create_checkbox: pg_docker_create_checkbox.set_sensitive(True)
            if pg_docker_name_entry: pg_docker_name_entry.set_sensitive(True)
            self._set_widget_value("docker_postgres_name", self.postgresql_defaults.get("docker_postgres_name"))
            if oracle_container_entry:
                oracle_container_entry.set_text("")
                oracle_container_entry.set_sensitive(False)
            if oracle_home_entry:
                oracle_home_entry.set_text("")
                oracle_home_entry.set_sensitive(False) 
        elif self.db_type == "oracle":
            self._set_widget_value("db_port", self.oracle_defaults.get("db_port"))
            self._set_widget_value("db_name", self.oracle_defaults.get("db_name"))
            self._set_widget_value("db_user", self.oracle_defaults.get("db_user"))
            self._set_widget_value("db_pass", self.oracle_defaults.get("db_pass"))
            self._set_widget_value("db_system_pass", self.oracle_defaults.get("db_system_pass"))
            if pg_docker_create_checkbox:
                pg_docker_create_checkbox.set_active(False)
                pg_docker_create_checkbox.set_sensitive(False)
            if pg_docker_name_entry:
                pg_docker_name_entry.set_text("")
                pg_docker_name_entry.set_sensitive(False)
            if oracle_container_entry: oracle_container_entry.set_sensitive(True)
            if oracle_home_entry:
                oracle_home_entry.set_sensitive(True)
                oracle_home_entry.set_text(self.oracle_defaults["oracle_docker_home"])

    def _toggle_branch_name_entry(self, widget=None):
        branch_entry = self.widgets.get("branch_name")
        enable_checkbox = self.widgets.get("clone_branch_enable")
        if branch_entry and enable_checkbox:
            is_enabled = enable_checkbox.get_active()
            branch_entry.set_sensitive(is_enabled)
            if not is_enabled: branch_entry.set_text("")

    def _build_command_list(self):
        cmd_parts = ['./setup.sh']
        if self._get_widget_value("setup_db") == True:
            cmd_parts.extend(['--db-type', self._get_widget_value("db_type")])
            if self._get_widget_value("db_type") == "postgresql":
                if self._get_widget_value("docker_postgres_create"):
                    cmd_parts.append('--docker-postgres-create')
                    val_docker_pg_name = self._get_widget_value("docker_postgres_name")
                    if self.widgets["docker_postgres_name"].get_sensitive() and \
                    (val_docker_pg_name != self.postgresql_defaults["docker_postgres_name"] or val_docker_pg_name):
                        if val_docker_pg_name: 
                            cmd_parts.extend(['--docker-postgres-name', val_docker_pg_name])            
            db_params_to_add = {
                "db_name": "--db-name", "db_host": "--db-host", "db_port": "--db-port",
                "db_user": "--db-user", "db_pass": "--db-pass", "db_system_pass": "--db-admin-pass"
            }
            for var_key, flag_name in db_params_to_add.items():
                val = self._get_widget_value(var_key)
                if val: 
                    cmd_parts.extend([flag_name, val])
            if self._get_widget_value("db_type") == "oracle":
                val_oracle_container = self._get_widget_value("oracle_docker_container")
                if val_oracle_container and self.widgets["oracle_docker_container"].get_sensitive():
                    cmd_parts.extend(['--oracle-docker-container', val_oracle_container])
                    val_oracle_home = self._get_widget_value("oracle_docker_home")
                    if self.widgets["oracle_docker_home"].get_sensitive() and \
                    (val_oracle_home != self.oracle_defaults["oracle_docker_home"] or val_oracle_home):
                        if val_oracle_home:
                            cmd_parts.extend(['--oracle-docker-home', val_oracle_home])
            server_param_map = {
                "idempiere_host": "--http-host", "idempiere_port": "--http-port",
                "idempiere_ssl_port": "--https-port"
            }
            for var_key, flag_name in server_param_map.items():
                val = self._get_widget_value(var_key)
                if val != str(self.defaults[var_key]) or val: 
                    cmd_parts.extend([flag_name, val])

        src_env_map = {
            "idempiere_source_folder": "--source", "source_url": "--repository-url"
        }
        for var_key, flag_name in src_env_map.items():
            val = self._get_widget_value(var_key)
            if val != self.defaults[var_key] or val: 
                 cmd_parts.extend([flag_name, val])
        
        #"eclipse_folder": "--eclipse"
        if self._get_widget_value("setup_ws") == True:
            val = self._get_widget_value("eclipse_folder")
            if val != self.defaults["eclipse_folder"] or val:
                cmd_parts.extend(["--eclipse", val])

        if self._get_widget_value("clone_branch_enable"):
            branch_name_val = self._get_widget_value("branch_name")
            if branch_name_val: cmd_parts.extend(['--branch', branch_name_val])

        if self._get_widget_value("load_idempiere_env"): cmd_parts.append('--load-idempiere-env')
        if not self._get_widget_value("setup_ws"): cmd_parts.append('--skip-setup-ws')
        if not self._get_widget_value("setup_db"): cmd_parts.append('--skip-setup-db')
        if self._get_widget_value("setup_ws") == True:
            if self._get_widget_value("install_copilot"): cmd_parts.append('--install-copilot')
        if self._get_widget_value("setup_db") == True:
            if not self._get_widget_value("migrate_existing_database"): cmd_parts.append('--skip-migration-script')
        return cmd_parts

    def _append_to_popup_textview(self, text):
        # This function is called via GLib.idle_add, so it runs in the main GTK thread.
        if self.output_window and self.output_textview_popup and self.output_window.get_visible():
            textview = self.output_textview_popup
            buffer = textview.get_buffer()
            mark = Gtk.TextBuffer.get_mark (buffer, "end");
            if mark is None:
              Gtk.TextBuffer.create_mark (buffer, "end", buffer.get_end_iter(), False);
              mark = Gtk.TextBuffer.get_mark (buffer, "end");
            
            # Insert text at the current end iterator
            buffer.insert(buffer.get_end_iter(), text) 
            
            # Now scroll the end mark onscreen.
            Gtk.TextView.scroll_mark_onscreen (textview, mark);
        return False # For GLib.idle_add source removal if this was directly scheduled

    def generate_command_and_display(self, widget):
        self.current_command_list_for_execution = self._build_command_list()
        display_command_str = shlex.join(self.current_command_list_for_execution)
        buffer = self.widgets["generated_command_text"].get_buffer()
        buffer.set_text(display_command_str)
        self.widgets["run_button"].set_sensitive(bool(self.current_command_list_for_execution))

    def _stream_output_to_ui_gtk(self, pipe):
        try:
            for line in iter(pipe.readline, ''):
                if self.output_window and self.output_window.get_visible(): # Check if popup is still there
                    GLib.idle_add(self._append_to_popup_textview, line)
                else: 
                    # If popup closed, no point in continuing to try and append
                    break 
        finally:
            if pipe: pipe.close()

    def _update_ui_post_execution(self, message_key):
        if self.output_window_stop_button:
            GLib.idle_add(self.output_window_stop_button.set_sensitive, False)
        if self.output_window_close_button:
            GLib.idle_add(self.output_window_close_button.set_sensitive, True)
        
        main_run_button = self.widgets.get("run_button")
        if main_run_button:
            GLib.idle_add(main_run_button.set_label, "Run Command")
            GLib.idle_add(main_run_button.set_sensitive, bool(self.current_command_list_for_execution))

        if self.output_window and self.output_textview_popup and self.output_window.get_visible():
            final_message = ""
            popup_message_title = "Info"
            popup_message_type = Gtk.MessageType.INFO

            if message_key == "success":
                final_message = "\n--- Command executed successfully. ---\n"
                popup_message_title = "Success"
            elif message_key == "stopped":
                final_message = "\n--- Process stopped by user. ---\n"
                popup_message_title = "Stopped"
                popup_message_type = Gtk.MessageType.WARNING
            elif isinstance(message_key, int): # Exit code for failure
                final_message = f"\n--- Command failed with exit code {message_key}. ---\n"
                popup_message_title = "Error"
                popup_message_type = Gtk.MessageType.ERROR
            elif message_key in ["script_not_found", "script_not_executable", "exception", "error_before_start_or_stopped"]:
                # Specific error messages are usually already printed by _handle_script_execution_gtk
                # We might just show a generic "Execution ended" or rely on the existing text.
                # For now, we won't add an extra generic message here for these,
                # but we will show a dialog if it's an exception.
                if message_key == "exception": # Should already be handled by _handle_script_execution_gtk's dialog
                    pass
                else: # For other pre-execution errors or early stops
                    final_message = f"\n--- Execution did not complete as expected ({message_key}). ---\n"
            
            if final_message:
                 GLib.idle_add(self._append_to_popup_textview, final_message)
            
            # Show dialog for explicit success/failure/stopped messages
            if message_key == "success" or message_key == "stopped" or isinstance(message_key, int):
                 GLib.idle_add(self._show_message_dialog, popup_message_title, final_message.strip(), popup_message_type)

        self.current_process = None 
        self.process_stopped_by_user = False
        return False # For GLib.idle_add

    def _handle_script_execution_gtk(self, command_list):
        self.process_stopped_by_user = False 
        try:
            script_path = command_list[0]
            if not os.path.exists(script_path):
                GLib.idle_add(self._show_message_dialog, "Error", f"Script not found: {script_path}", Gtk.MessageType.ERROR)
                if self.output_window and self.output_textview_popup: GLib.idle_add(self._append_to_popup_textview, f"\n--- Error: {script_path} not found. ---\n")
                GLib.idle_add(self._update_ui_post_execution, "script_not_found")
                return
            if not os.access(script_path, os.X_OK):
                GLib.idle_add(self._show_message_dialog, "Error", f"Script not executable: {script_path}", Gtk.MessageType.ERROR)
                if self.output_window and self.output_textview_popup: GLib.idle_add(self._append_to_popup_textview, f"\n--- Error: {script_path} not executable. Please use chmod +x. ---\n")
                GLib.idle_add(self._update_ui_post_execution, "script_not_executable")
                return

            if self.output_window_stop_button: GLib.idle_add(self.output_window_stop_button.set_sensitive, True)
            if self.output_window_close_button: GLib.idle_add(self.output_window_close_button.set_sensitive, False)

            self.current_process = subprocess.Popen(command_list, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, bufsize=1, universal_newlines=True, preexec_fn=os.setsid if os.name != "nt" else None)
            
            stdout_thread = threading.Thread(target=self._stream_output_to_ui_gtk, args=(self.current_process.stdout,), daemon=True)
            stderr_thread = threading.Thread(target=self._stream_output_to_ui_gtk, args=(self.current_process.stderr,), daemon=True)
            stdout_thread.start(); stderr_thread.start()

            def check_completion_gtk():
                if not self.current_process: 
                    # This implies process was stopped/cleared externally or before proper start.
                    # _update_ui_post_execution should handle this state.
                    return False 

                # Check if process is still considered running by polling its state
                process_poll_result = self.current_process.poll()

                # If user initiated stop, and threads are done, or process is confirmed stopped
                if self.process_stopped_by_user:
                    if not (stdout_thread.is_alive() or stderr_thread.is_alive()) or process_poll_result is not None:
                        GLib.idle_add(self._update_ui_post_execution, "stopped")
                        return False # Stop checking

                # If process is naturally running or threads are still active
                if (stdout_thread.is_alive() or stderr_thread.is_alive()) or process_poll_result is None:
                    GLib.timeout_add(100, check_completion_gtk); return False 
                
                # Process has finished naturally
                if self.current_process.returncode == 0:
                    GLib.idle_add(self._update_ui_post_execution, "success")
                else:
                    GLib.idle_add(self._update_ui_post_execution, self.current_process.returncode)
                return False 
            GLib.timeout_add(100, check_completion_gtk)
        except Exception as e:
            error_message = f"An execution error occurred: {e}"
            if self.output_window and self.output_textview_popup: GLib.idle_add(self._append_to_popup_textview, f"\n--- {error_message} ---\n")
            GLib.idle_add(self._show_message_dialog, "Execution Error", error_message, Gtk.MessageType.ERROR)
            GLib.idle_add(self._update_ui_post_execution, "exception")


    def run_command(self, widget):
        if not self.current_command_list_for_execution:
            self._show_message_dialog("Error", "No command generated. Please generate first.", Gtk.MessageType.ERROR); return
        
        self._create_output_window() 
        
        if self.output_textview_popup:
            self.output_textview_popup.get_buffer().set_text("") 
            display_cmd = shlex.join(self.current_command_list_for_execution)
            self._append_to_popup_textview(f"Executing: {display_cmd}\n\n")
        
        self.widgets["run_button"].set_label("Running..."); self.widgets["run_button"].set_sensitive(False)
        
        # Initial state for popup buttons when execution starts
        if self.output_window_stop_button: self.output_window_stop_button.set_sensitive(True)
        if self.output_window_close_button: self.output_window_close_button.set_sensitive(False)

        threading.Thread(target=self._handle_script_execution_gtk, args=(self.current_command_list_for_execution,), daemon=True).start()

    def reset_defaults(self, widget, initial_setup=False):
        for key, value in self.defaults.items():
            if key in self.widgets: self._set_widget_value(key, value)
        self._on_db_type_changed(self.widgets.get("db_type"))
        self._toggle_branch_name_entry() 
        self.widgets["generated_command_text"].get_buffer().set_text("")
        
        if self.output_window and self.output_textview_popup:
            self.output_textview_popup.get_buffer().set_text("")
        
        run_button = self.widgets.get("run_button")
        if run_button:
            run_button.set_label("Run Command")
            run_button.set_sensitive(bool(self.current_command_list_for_execution))

        if self.output_window_stop_button: self.output_window_stop_button.set_sensitive(False)
        if self.output_window_close_button: self.output_window_close_button.set_sensitive(True)

        self.current_process = None
        self.process_stopped_by_user = False

        if widget and not initial_setup: 
            self._show_message_dialog("Reset", "Form has been reset to default values.", Gtk.MessageType.INFO)

    def _show_message_dialog(self, title, message, message_type):
        dialog = Gtk.MessageDialog(transient_for=self.window, flags=0, message_type=message_type, buttons=Gtk.ButtonsType.OK, text=title)
        dialog.format_secondary_text(message); dialog.run(); dialog.destroy()
        return False

if __name__ == '__main__':
    if sys.platform != "win32":
      GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGINT, Gtk.main_quit)
    app = SetupScriptGTKUI()
    Gtk.main()
