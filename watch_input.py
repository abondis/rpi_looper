from multiprocessing import Process
import time
import select
import liblo

# handle states
# for later use
record_state = False
play_state = False
select_state = False

# where are the gpio files
gpio_base = '/sys/class/gpio/'
def write_once(path, value):
    f = open(path, 'w')
    f.write(value)
    f.close()
    return

def setup_pin(pin):
    """Setup pin as input"""
    pin = str(pin)
    global gpio_base
    pin_path = gpio_base + 'gpio' + pin
    # unexport the pin just in case
    try:
        write_once(gpio_base +'unexport', pin)
    except:
        pass
    # export pin
    write_once(gpio_base +'export', pin)
    # open file to poll
    f = open(pin_path + '/value', 'r')
    # set pin as input
    write_once(pin_path + '/direction', 'in')
    # set event trigger as both ( rising, falling)
    # not sure it's necessary since we poll value file
    write_once(pin_path + '/edge', 'both')
    po = select.poll()
    po.register(f, select.POLLPRI)
    return po, f

def watch_select(po, f):
    """Watch select button and update osc"""
    global select_state
    while 1:
        events = po.poll()
        # if not, poll will always see something new
        state = f.read(1)
        if state != select_state:
            liblo.send(target, '/select')
            select_state = not select_state

def watch_play(po, f):
    """Watch play button and update osc"""
    global play_state
    while 1:
        events = po.poll()
        # if not, poll will always see something new
        state = f.read(1)
        if state != select_state:
            liblo.send(target, '/play')
            play_state = not play_state

def watch_record(po, f):
    """Watch record button and update osc"""
    global record_state
    while 1:
        events = po.poll()
        # if not, poll will always see something new
        state = f.read(1)
        if state != select_state:
            liblo.send(target, '/record')
            record_state = not record_state

target = liblo.Address('osc.udp://127.0.0.1:6449/')

# BCM pin number
select_pin = 22
record_pin = 23
play_pin = 24

# threads to handle independant/non blocking inputs
record_btn = Process(
                target=watch_record,
                args=(setup_pin(record_pin)))
record_btn.start()

while 1:
    time.sleep(1000)
