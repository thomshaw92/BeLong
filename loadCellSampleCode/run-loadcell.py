import tkinter as tk
from tkinter import ttk, simpledialog, messagebox
import matplotlib.pyplot as plt
from matplotlib.figure import Figure
import matplotlib.animation as animation
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import csv
import os
import datetime
from loadCell import LoadCell

# Initialize LoadCell
lc = LoadCell("COM5")
lc.setLoadCellGradient(0, 0, 100, 100000)
lc.zeroLoadCell(10)

# Sampling and display parameters
Fs = 10  # Sample rate in Hz
Ts = 1000 / Fs  # Sample period in ms
dispN = 200  # Number of points to display in plot

        
class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title('Load Cell Recording')
        self.max_force = None  # Initialize max force tracking
        # Prompt for participant name via GUI
        self.participant_name = simpledialog.askstring("Participant Name", "Enter participant name:", parent=self)
        
        # Location selection dropdown
        self.location_var = tk.StringVar()
        self.location_dropdown = ttk.Combobox(self, textvariable=self.location_var, state="readonly",
                                              values=["Left UL", "Right UL", "Left LL", "Right LL"])
        self.location_dropdown.pack()
        self.location_dropdown.set("Select Location")  # Default value

        self.location_var.trace('w', self.update_location)  # Update location when changed

        # Create matplotlib figure and axes
        self.fig, self.ax = plt.subplots()
        self.canvas = FigureCanvasTkAgg(self.fig, master=self)  # A tk.DrawingArea.
        self.canvas.draw()
        self.canvas.get_tk_widget().pack(side=tk.TOP, fill=tk.BOTH, expand=1)

        # Buttons for controlling recording
        self.start_button = tk.Button(self, text="Start Recording", bg="green", fg="white", padx=10, pady=5, command=self.start_recording)
        self.start_button.pack(side=tk.LEFT, padx=(20, 10), pady=(10, 10))
        
        self.stop_button = tk.Button(self, text="Stop Recording", bg="red", fg="white", padx=10, pady=5, command=self.stop_recording)
        self.stop_button.pack(side=tk.RIGHT, padx=(10, 20), pady=(10, 10))

        self.ani = None

    def update_location(self, *args):
        # Format the directory name based on participant name
        self.directory_path = os.path.join(os.getcwd(), self.participant_name)  # os.getcwd() gets the current working directory
        os.makedirs(self.directory_path, exist_ok=True)  # Create the directory if it doesn't exist

        # Update file paths for CSV and PNG to include the participant's directory
        self.datetime_str = datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
        location = self.location_var.get().replace(" ", "_")
        self.csv_filename = os.path.join(self.directory_path, f"data_{location}_{self.datetime_str}.csv")
        self.png_filename = os.path.join(self.directory_path, f"plot_{location}_{self.datetime_str}.png")

        # Create or overwrite a new CSV file for the new location
        with open(self.csv_filename, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            csv_writer.writerow(['Timestamp', 'ADC Reading'])

    def animate(self, i, xs, ys):
        # Read data from LoadCell
        adcRead = lc.readLoadCellConverted()
        ys.append(adcRead)
        xs.append(i / Fs)
        xs, ys = xs[-dispN:], ys[-dispN:]

        # Update max force
        if self.max_force is None or adcRead > self.max_force:
            self.max_force = adcRead

        # Update plot
        self.ax.clear()
        self.ax.plot(xs, ys)
        self.ax.set_title('ADC Readings')
        self.ax.set_xlabel('Time (s)')
        self.ax.set_ylabel('ADC Reading')

        # Log data to CSV
        with open(self.csv_filename, 'a', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            csv_writer.writerow([datetime.datetime.now().isoformat(), adcRead])
    
    def start_recording(self):
        # Start animation for real-time plotting
        if self.ani is None and self.location_var.get() != "Select Location":
            self.ani = animation.FuncAnimation(self.fig, self.animate, fargs=([], []), interval=Ts)
            self.canvas.draw()
        else:
            messagebox.showwarning("Warning", "Please select a location before starting the recording.")
            
    def stop_recording(self):
        # Stop animation and save plot
        if self.ani is not None:
            self.ani.event_source.stop()
            self.ani = None
            self.fig.savefig(self.png_filename)
            
            # Save max force to a text file
            max_force_filename = os.path.join(self.directory_path, f"max_force_{self.location_var.get().replace(' ', '_')}_{self.datetime_str}.txt")
            with open(max_force_filename, 'w') as f:
                f.write(f"Max Force for this trial: {self.max_force}\n")

            # Reset max force for next trial
            self.max_force = None

            messagebox.showinfo("Recording Stopped", f"Recording stopped. Plot saved as {self.png_filename} and max force saved as {max_force_filename}.")

if __name__ == "__main__":
    app = App()
    app.mainloop()
