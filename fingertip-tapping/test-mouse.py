from psychopy import visual, event, core

# Create a window
win = visual.Window(fullscr=True, color='grey')

# Instructions
instruction = visual.TextStim(win, text="Click the mouse to record a press. Press 'escape' to exit.", color='black')
instruction.draw()
win.flip()

# Initialize mouse
mouse = event.Mouse(win=win)

# Loop to check for mouse clicks or escape key
while True:
    if 'escape' in event.getKeys():  # Check for escape key to exit
        break
    
    buttons = mouse.getPressed()
    if buttons[0]:  # If the left mouse button is clicked
        # Display 'Click' text for 100ms
        click_text = visual.TextStim(win, text="Click", color='black')
        click_text.draw()
        win.flip()
        core.wait(0.1)  # Wait for 100ms
        win.flip()  # Clear the 'Click' message
        mouse.clickReset()  # Reset mouse to detect next click

# Close the window
win.close()
core.quit()
