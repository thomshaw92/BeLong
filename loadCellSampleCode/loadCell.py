import serial
from time import sleep

class LoadCell():
    
    def __init__(self, COM):
        # Serial settings
        self.COMPort = COM
        self.baudrate = 115200
        self.bytesize = 8
        self.stopbits = serial.STOPBITS_ONE
        self.parity = serial.PARITY_NONE
        self.timeout = None

        self.lc_grad = None
        self.lc_zero = None

        # Create serial port
        self.sPort = serial.Serial(port=self.COMPort, 
                                   baudrate=self.baudrate,
                                   timeout=self.timeout)
        sleep(0.1)
        
        
    def readLoadCellRaw(self):
        # Write 'R' to read data
        self.sPort.write('R'.encode('utf-8'))

        # Read 3 bytes of data
        data = self.sPort.read(3)
        # Convert back to 16-bit 2's comp int
        force = (data[0] << 16) | (data[1] << 8) | (data[2])
        if (force & 0x800000):
            force = -1 * ((force ^ 0xFFFFFF) + 1)
        
        return force

    def closeLoadCell(self):
        self.sPort.close()

    def zeroLoadCell(self, n):
        # Measures average zero-point of load-cell n-times
        zero = 0
        for i in range(n):
            zero += self.readLoadCellRaw()
        zero /= n
        self.lc_zero = zero

    def setLoadCellGradient(self, weight1:float, reading1:int, weight2:float, reading2:int):
        # Calculates load-cell gradient from weights and readings
        #
        # weight1:  weight applied to load cell (grams recommended)
        # reading1: raw ADC reading from weight1
        # weight2:  second weight applied to load cell (same units as weight1)
        # reading2: raw ADC reading from weight2
        #
        # IMPORTANT: Ensure same straps/hardware used when connecting each weight

        self.lc_grad = (reading2 - reading1) / (weight2 - weight1)
    
    def readLoadCellConverted(self):
        # Reads raw ADC reading and converts to units set by gradient and zero
        raw = self.readLoadCellRaw()
        weight = (raw - self.lc_zero) / self.lc_grad
        return weight