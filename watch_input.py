from __future__ import print_function
from multiprocessing import Process
import time
import select
import liblo
import sys
print = lambda x: sys.stdout.write("%s\n" % x)

# handle states
# for later use
record_state = False
play_state = False
select_state = False
selected_voice = 0
max_voices = 8

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
    print(pin_path)
    # unexport the pin just in case
    #try:
    write_once(gpio_base +'unexport', pin)
   # except:
   #     pass
    # export pin
    write_once(gpio_base +'export', pin)
    # open file to poll
    # set pin as input
    write_once(pin_path + '/direction', 'in')
    # set event trigger as both ( rising, falling)
    # not sure it's necessary since we poll value file
    write_once(pin_path + '/edge', 'both')
    po = select.epoll()
    f = open(pin_path + '/value', 'r')
    f.read()
    po.register(f, select.EPOLLPRI)
    print(str(f))
    return po, f

def watch_select(po, f):
    """Watch select button and update osc"""
    global select_state
    global selected_voice
    while 1:
        events = po.poll()
        # if not, poll will always see something new
        f.seek(0)
        state = f.read(1)
        if state != select_state:
            print("select "+str(selected_voice+1))
            selected_voice += 1
            if selected_voice > max_voices:
                selected_voice = 0
            select_state = state

def watch_play(po, f):
    """Watch play button and update osc"""
    global play_state
    global selected_voice
    while 1:
        events = po.poll()
        # if not, poll will always see something new
        f.seek(0)
        state = f.read(1)
        if state != play_state:
            print("play "+str(selected_voice))
            liblo.send(target, '/play', ('i', selected_voice))
            play_state = state

def watch_record(po, f):
    """Watch record button and update osc"""
    global record_state
    global selected_voice
    while 1:
        events = po.poll()
        # if not, poll will always see something new
        f.seek(0)
        state = f.read(1)
        if state != record_state:
            print("record "+str(selected_voice))
            liblo.send(target, '/record', ('i', selected_voice))
            #record_state = not record_state
            record_state = state

target = liblo.Address('osc.udp://127.0.0.1:6449/')

# BCM pin number
select_pin = 23
record_pin = 22
play_pin = 24

# threads to handle independant/non blocking inputs
record_btn = Process(
                target=watch_record,
                args=(setup_pin(record_pin)))
#play_btn = Process(
                #target=watch_play,
                #args=(setup_pin(play_pin)))
#select_btn = Process(
                #target=watch_select,
                #args=(setup_pin(select_pin)))
#play_btn.start()
#select_btn.start()
record_btn.start()

while 1:
    time.sleep(1000)
