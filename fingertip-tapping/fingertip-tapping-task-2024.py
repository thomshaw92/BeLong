"""
fingertip-tapping.py
A PsychoPy experiment to measure fingertip tapping speed.

The script will display instructions to the participant, asking them to tap a specified finger on the space bar as fast as they can. This will be repeated for each finger three times, in a random order. 
Participants are instructed to wait for the finger instruction on the screen before beginning each trial.

At the end of each trial, the number of taps is saved, and an average is calculated for each finger.

The data will be written to a CSV file at a user-specified location.

This script was written for use with PsychoPy v2021.1.4.

Author: Tom Shaw t.shaw@uq.edu.au
Date: 2023 06 12
"""
from psychopy import visual, core, event, gui
import csv
import random
from datetime import datetime

# Prompt for file save location using the gui module
filename = gui.fileSaveDlg(initFileName=datetime.now().strftime("%Y-%m-%d_%H-%M-%S_tapping_data.csv"))
if not filename:
    core.quit()

# Initialize fullscreen window after file location has been chosen
win = visual.Window(fullscr=True, color='grey')
# Display instruction screen before starting the trials
instruction_text = "Prepare to tap as fast as you can on the mouse button or foot pad. You will do this for each finger and both feet, left and right side, twice. Press space to start"
instruction_screen = visual.TextStim(win, text=instruction_text, pos=(0, 0), color='black')
instruction_screen.draw()
win.flip()
event.waitKeys(keyList=['space'])


# Experiment setup
digits = ['THUMB', 'INDEX finger', 'MIDDLE finger', 'RING finger', 'LITTLE finger', 'FOOT']
#'index finger', 'middle finger', 'ring finger', 'little finger', 'foot'
sides = ['LEFT', 'RIGHT']
trials_per_digit = 2
trials = [(digit, side) for digit in digits for side in sides for _ in range(trials_per_digit)]
random.shuffle(trials)

# Results initialization
results = []
# Initialize list to store keypress counts for each trial

mouse = event.Mouse(win=win)  # Initialize mouse
# Main experiment loop
for digit, side in trials:
    keypresses = 0  # Reset keypresses counter for each trial
  
    # Instruction and readiness prompt
    instruction_screen_text = f'Prepare to press your {digit} on {side} side.\nPress the spacebar when ready.'
    instruction_screen = visual.TextStim(win, text=instruction_screen_text, color='black')
    instruction_screen.draw()
    win.flip()
    event.waitKeys(keyList=['space'])
    
    # Countdown
    for i in range(3, 0, -1):
        countdown = visual.TextStim(win, text=str(i), color='black')
        countdown.draw()
        win.flip()
        core.wait(1)
    
    # Trial execution modified for mouse clicks
    go_text = visual.TextStim(win, text=f'GO! Press your {side} {digit} as fast as you can!!', color='black')
    go_text.draw()
    win.flip()
    start_time = core.getTime()
    mouse.clickReset()  # Reset mouse click count at the start of each trial
    while core.getTime() - start_time < 10:
        buttons = mouse.getPressed()  # Check for mouse clicks
        if buttons[0]:  # If the left mouse button is clicked
            keypresses += 1
            while mouse.getPressed()[0]:  # Wait for the button to be released
                pass
        if 'escape' in event.getKeys():
            win.close()
            core.quit()
    
    stop_text = visual.TextStim(win, text='STOP!', color='black')
    stop_text.draw()
    win.flip()
    core.wait(2)  # Display stop text for 2 seconds

    # Save trial result with the number of mouse clicks
    results.append({'digit': digit, 'side': side, 'keypresses': keypresses})

# Adjusted results initialization to account for digit and side
total_keypresses = {(digit, side): 0 for digit in digits for side in sides}
for result in results:
    total_keypresses[(result['digit'], result['side'])] += result['keypresses']

# Calculate averages for each digit and side
averages = {(digit, side): total_keypresses[(digit, side)] / trials_per_digit for digit in digits for side in sides}

# Writing results to CSV with corrected averages
with open(filename, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['Digit', 'Side', 'Total Keypresses', 'Average Keypresses'])
    for digit, side in total_keypresses:
        writer.writerow([digit, side, total_keypresses[(digit, side)], averages[(digit, side)]])

# Display averages at the end, adjusted for digit and side
average_text = 'Averages:\n' + '\n'.join([f'{digit} {side}: {avg:.2f}' for (digit, side), avg in averages.items()])
average_display = visual.TextStim(win, text=average_text, color='black')
average_display.draw()
win.flip()
core.wait(5)

# Display end message
end_text = visual.TextStim(win, text='End of the experiment. Thank you!', color='black')
end_text.draw()
win.flip()
core.wait(5)