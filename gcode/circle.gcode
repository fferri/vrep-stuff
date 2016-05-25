(Draw a Circle)

(This program draws a 1" diameter circle about the origin in the X-Y plane.)
(It should begin by seeking the Z-axis to 0.25", travel to X=-0.5 and Y=0.0,)
(and lower back to Z=0.0. The program will then draw a clockwise circle at a)
(slow feedrate. When finished, it will lift the Z-axis up 0.1" and then seek)
(back to X=0.0, Y=0.0, and Z=0.25 to complete.)

G17 G20 G90 G94 G54
G0 Z2.5
X-5 Y0
Z1
G01 Z0 F150
F75
G02 X0 Y5 I5 J0
G02 X5 Y0 I0 J-5
G02 X0 Y-5 I-5 J0
G02 X-5 Y0 I0 J5
G01 Z1 F150
G00 X0 Y0 Z2.5
